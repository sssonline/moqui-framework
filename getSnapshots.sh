#!/usr/bin/env bash

# This program retrieves snapshots from remote systems and loads them into moqui.
# It requires a .env file with:
#   VALID_DATASETS, COMMON_SNAPSHOT_URL_PATH, SNAPSHOT_PATH,
#   MAX_HEAP_THRESHOLD_PERCENT, NON_HEAP_MEMORY_BUFFER_GB,
#   and for each dataset in VALID_DATASETS: BASE_URL_<DS>, DATASET_AUTH_<DS>
#
# Usage examples:
#   ./getSnapshots.sh              # all datasets
#   ./getSnapshots.sh GS GW GF     # specific datasets
#   ./getSnapshots.sh GS-2021-01-01b  # specific dated suffix

set -o nounset
set -o errexit
set -o pipefail

# -------------------------
# Functions
# -------------------------

calculate_max_heap_size() {
    OS_TYPE=$(uname)

    if [ "$OS_TYPE" = "Darwin" ]; then
        total_mem_bytes=$(sysctl -n hw.memsize)
    elif [ "$OS_TYPE" = "Linux" ]; then
        total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        total_mem_bytes=$((total_mem_kb * 1024))
    else
        echo "Unsupported operating system: $OS_TYPE"
        exit 1
    fi

    threshold_bytes=$(( total_mem_bytes * MAX_HEAP_THRESHOLD_PERCENT / 100 ))
    buffer_bytes=$(( NON_HEAP_MEMORY_BUFFER_GB * 1024 * 1024 * 1024 ))

    minus_buffer_bytes=$(( total_mem_bytes - buffer_bytes ))

    if [ "$threshold_bytes" -gt "$minus_buffer_bytes" ]; then
        max_heap_bytes=$threshold_bytes
    else
        max_heap_bytes=$minus_buffer_bytes
    fi

    if [ "$max_heap_bytes" -le 0 ]; then
        echo "Error: Calculated Java heap size is non-positive."
        exit 1
    fi

    max_heap_mb=$(( max_heap_bytes / (1024 * 1024) ))
    echo "${max_heap_mb}m"
}

is_valid_dataset() {
    local dataset="$1"
    for valid in "${valid_datasets[@]}"; do
        if [ "$dataset" = "$valid" ]; then
            return 0
        fi
    done
    return 1
}

run_backup() {
    local label="$1"
    if [ -x ./backupH2.sh ]; then
        if [ -d runtime/db/h2 ] || [ -d ./runtime/db/h2 ]; then
            ./backupH2.sh "$label" || echo "backupH2.sh failed for $label"
        else
            echo "Skipping backup for $label: runtime/db/h2 not found."
        fi
    else
        echo "Skipping backup for $label: backupH2.sh not found or not executable."
    fi
}

chunk_and_process_dataset() {
    local dataset="$1"
    local file="$2"

    local temp_dir
    temp_dir=$(mktemp -d -t snapchunk.XXXXXX)

    unzip -q "$file" -d "$temp_dir"

    # Collect XML files (alphabetical)
    files=()
    while IFS= read -r line; do
        files+=("$line")
    done < <(find "$temp_dir" -type f -name '*.xml' | sort)

    local total_files=${#files[@]}
    local chunk_size="${CHUNK_SIZE:-1000}"

    if [ "$total_files" -eq 0 ]; then
        echo "No XML files found in $file"
        rm -rf "$temp_dir"
        return 1
    fi

    local chunk_count=$(( (total_files + chunk_size - 1) / chunk_size ))
    echo "Splitting $total_files files into $chunk_count chunks of up to $chunk_size files each."

    for ((i = 0; i < chunk_count; i++)); do
        local chunk_dir="$temp_dir/chunk_$i"
        mkdir "$chunk_dir"

        for ((j = 0; j < chunk_size; j++)); do
            local idx=$(( i * chunk_size + j ))
            [ "$idx" -ge "$total_files" ] && break
            cp "${files[$idx]}" "$chunk_dir/"
        done

        local chunk_zip="$temp_dir/${dataset}_chunk_$i.zip"
        (
            cd "$chunk_dir"
            zip -q -r "$chunk_zip" .
        )

        echo "Processing chunk $i ($chunk_zip)..."
        export LOAD_DELAY_INDEX_ON_CREATE=true
        java -server -Djava.awt.headless=true -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx"$MAX_HEAP_SIZE" -jar moqui.war load raw location="$chunk_zip"
        unset LOAD_DELAY_INDEX_ON_CREATE

        rm -rf "$chunk_dir" "$chunk_zip"
    done

    rm -rf "$temp_dir"
}

process_dataset() {
    local dataset="$1"

    # Determine base dataset and suffix
    if [[ "$dataset" =~ ^([A-Z]{2})-([0-9]{4}-[0-9]{2}-[0-9]{2}.*)$ ]]; then
        base_dataset="${BASH_REMATCH[1]}"
        dataset_suffix="${BASH_REMATCH[2]}"
        file="${SNAPSHOT_PATH/#\~/$HOME}/${dataset}.zip"
    else
        base_dataset="$dataset"
        dataset_suffix="$d"
        file="${SNAPSHOT_PATH/#\~/$HOME}/${base_dataset}-${dataset_suffix}.zip"
    fi

    file=$(eval echo "$file")

    # Find dataset index
    local dataset_index=-1
    for i in "${!valid_datasets[@]}"; do
        if [ "${valid_datasets[$i]}" = "$base_dataset" ]; then
            dataset_index=$i
            break
        fi
    done

    if [ "$dataset_index" -eq -1 ]; then
        echo "Error: Dataset $base_dataset not in VALID_DATASETS."
        return 1
    fi

    url="${dataset_urls[$dataset_index]}${COMMON_SNAPSHOT_URL_PATH}${base_dataset}-${dataset_suffix}.zip"

    if [ ! -f "$file" ]; then
        echo "File $file not found. Downloading..."
        curl -v -u "${dataset_auth[$dataset_index]}" --insecure "$url" --output "$file"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to download $file."
            return 1
        fi
    else
        echo "File $file already exists. Skipping download."
    fi

    gradle cleanAll
    gradle build

    local start_import
    start_import=$(date +%s)

    # Chunked load
    chunk_and_process_dataset "$dataset" "$file"

    local start_indexing
    start_indexing=$(date +%s)

    export LOAD_INIT_DATASOURCE_TABLES=true
    java -server -Djava.awt.headless=true -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx"$MAX_HEAP_SIZE" -jar moqui.war load raw types=none
    unset LOAD_INIT_DATASOURCE_TABLES

    local end
    end=$(date +%s)

    # Backups
    if [[ "$dataset" =~ ^[A-Z]{2}- ]]; then
        run_backup "$dataset"
    else
        run_backup "$base_dataset"
        run_backup "${base_dataset}-${dataset_suffix}"
    fi

    # Durations
    local import_duration=$(( start_indexing - start_import ))
    local indexing_duration=$(( end - start_indexing ))
    local total_duration=$(( end - start_import ))

    import_durations+=("$import_duration")
    indexing_durations+=("$indexing_duration")
    total_durations+=("$total_duration")
}

# -------------------------
# Main
# -------------------------

# Load .env first
if [ -f ".env" ]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
else
    echo "Error: .env file not found. Please provide credentials."
    exit 1
fi

d=$(date +%Y-%m-%d)
export scheduled_job_check_time=0

# Validate env vars
if [ -z "${VALID_DATASETS:-}" ] || \
   [ -z "${COMMON_SNAPSHOT_URL_PATH:-}" ] || \
   [ -z "${SNAPSHOT_PATH:-}" ] || \
   [ -z "${MAX_HEAP_THRESHOLD_PERCENT:-}" ] || \
   [ -z "${NON_HEAP_MEMORY_BUFFER_GB:-}" ]; then
    echo "Error: Missing required environment variables in .env."
    exit 1
fi

# Split datasets
IFS=' ' read -r -a valid_datasets <<< "$VALID_DATASETS"

# Build URL/auth arrays
dataset_urls=()
dataset_auth=()
for dataset in "${valid_datasets[@]}"; do
    base_url_var="BASE_URL_${dataset}"
    auth_var="DATASET_AUTH_${dataset}"

    if [ -z "${!base_url_var:-}" ] || [ -z "${!auth_var:-}" ]; then
        echo "Error: Missing $base_url_var or $auth_var for dataset $dataset."
        exit 1
    fi
    dataset_urls+=("${!base_url_var}")
    dataset_auth+=("${!auth_var}")
done

# Heap size now that env vars exist
MAX_HEAP_SIZE=$(calculate_max_heap_size)
echo "Setting Java maximum heap size to: $MAX_HEAP_SIZE"

# Parse CLI args
selected_datasets=()
if [ "$#" -eq 0 ]; then
    selected_datasets=("${valid_datasets[@]}")
else
    for arg in "$@"; do
        if [[ "$arg" =~ ^([A-Z]{2})-([0-9]{4}-[0-9]{2}-[0-9]{2}.*)$ ]]; then
            base_dataset="${BASH_REMATCH[1]}"
            if is_valid_dataset "$base_dataset"; then
                selected_datasets+=("$arg")
            else
                echo "Invalid dataset: $base_dataset. Valid: ${valid_datasets[*]}"
                exit 1
            fi
        elif is_valid_dataset "$arg"; then
            selected_datasets+=("$arg")
        else
            echo "Invalid dataset: $arg. Valid: ${valid_datasets[*]}"
            exit 1
        fi
    done
fi

# Duration arrays
import_durations=()
indexing_durations=()
total_durations=()

for dataset in "${selected_datasets[@]}"; do
    echo "Processing dataset: $dataset"
    process_dataset "$dataset"
done

unset scheduled_job_check_time

echo
echo "Execution times:"
for i in "${!selected_datasets[@]}"; do
    dataset="${selected_datasets[$i]}"
    import_duration="${import_durations[$i]}"
    indexing_duration="${indexing_durations[$i]}"
    total_duration="${total_durations[$i]}"

    echo "$dataset Import Duration: $((import_duration / 60)) minutes and $((import_duration % 60)) seconds."
    echo "$dataset Indexing Duration: $((indexing_duration / 60)) minutes and $((indexing_duration % 60)) seconds."
    echo "$dataset Total Duration: $((total_duration / 60)) minutes and $((total_duration % 60)) seconds."
    echo
done
