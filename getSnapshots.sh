#!/usr/bin/env bash

# This program retrieves snapshots from remote systems and loads them into moqui.
# It requires that you create a .env file with the following variables:
# For each dataset in VALID_DATASETS, a corresponding BASE_URL and DATASET_AUTH variable must be defined.
# Once this file is in place, this may be in various ways:
# 1. Run the script with no arguments to process all datasets.
# 2. Run the script with one or more dataset codes to process only those datasets.
# 3. Run the script with a dataset code and a date suffix to process a specific snapshot.
# Example: ./getGebbersSnapshots.sh GS GW GF
# Example: ./getGebbersSnapshots.sh GS-2021-01-01 GW-2021-01-01 GF-2021-01-01
# Example: ./getGebbersSnapshots.sh GS-2021-01-01b
#SNAPSHOT_PATH="$HOME/dbp/Work/Payroll/Backups"
#MAX_HEAP_THRESHOLD_PERCENT=80
#NON_HEAP_MEMORY_BUFFER_GB=8
#
#COMMON_SNAPSHOT_URL_PATH=/apps/tools/Entity/DataSnapshot/downloadSnapshot?filename=
#
#VALID_DATASETS="GS GW GF"
#
#BASE_URL_GS=http://salary.gebbersfarms.com:8083
#DATASET_AUTH_GS="backup:PASSWORD"
#
#BASE_URL_GW=http://warehouse.gebbersfarms.com:8081
#DATASET_AUTH_GW="backup:PASSWORD"
#
#BASE_URL_GF=http://orchard.gebbersfarms.com:8082
#DATASET_AUTH_GF="backup:PASSWORD"

# Corresponding authentication credentials for each dataset
if [[ -f ".env" ]]; then
    set -a  # Automatically export all variables
    source .env
    set +a  # Disable automatic exporting
else
    echo "Error: .env file not found. Please provide credentials."
    exit 1
fi

d=$(date +%Y-%m-%d)
export scheduled_job_check_time=0

# Validate required environment variables
if [[ -z "$VALID_DATASETS" || -z "$COMMON_SNAPSHOT_URL_PATH" || -z "$SNAPSHOT_PATH" || -z "$MAX_HEAP_THRESHOLD_PERCENT" || -z "$NON_HEAP_MEMORY_BUFFER_GB" ]]; then
    echo "Error: One or more required environment variables are missing in the .env file."
    exit 1
fi

# Split VALID_DATASETS into an array
if [[ -n "$VALID_DATASETS" ]]; then
    IFS=' ' read -r -a valid_datasets <<< "$VALID_DATASETS"
else
    echo "Error: VALID_DATASETS is not defined or empty in .env."
    exit 1
fi

# Initialize dataset URLs and auth arrays
dataset_urls=()
dataset_auth=()

# Build dataset_urls and dataset_auth dynamically
for dataset in "${valid_datasets[@]}"; do
    base_url_var="BASE_URL_${dataset}"
    auth_var="DATASET_AUTH_${dataset}"

    # Debugging: Print the values being resolved
#    echo "Processing dataset: $dataset"
#    echo "Base URL var: $base_url_var, Value: ${!base_url_var}"
#    echo "Auth var: $auth_var, Value: ${!auth_var}"

    # Check if required variables exist
    if [[ -z "${!base_url_var}" || -z "${!auth_var}" ]]; then
        echo "Error: Missing environment variable(s) for dataset $dataset. Expected $base_url_var and $auth_var."
        exit 1
    fi

    # Append to arrays
    dataset_urls+=("${!base_url_var}")
    dataset_auth+=("${!auth_var}")
done

# Debug: Print resolved datasets, URLs, and auths
#echo "Valid datasets: ${valid_datasets[*]}"
#echo "Dataset URLs: ${dataset_urls[*]}"
#echo "Dataset Auth: ${dataset_auth[*]}"

# Function to check if a dataset is valid
is_valid_dataset() {
    local dataset="$1"
    for valid in "${valid_datasets[@]}"; do
        if [[ "$dataset" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

# Process command-line arguments
selected_datasets=()
if [[ $# -eq 0 ]]; then
    # Default to all datasets if no arguments provided
    selected_datasets=("${valid_datasets[@]}")
else
    for arg in "$@"; do
        # Check if the argument matches a dataset with an optional suffix
        if [[ "$arg" =~ ^([A-Z]{2})-([0-9]{4}-[0-9]{2}-[0-9]{2}.*)$ ]]; then
            base_dataset="${BASH_REMATCH[1]}"
            if is_valid_dataset "$base_dataset"; then
                selected_datasets+=("$arg")
            else
                echo "Invalid dataset: $base_dataset. Valid options are: ${valid_datasets[*]}"
                exit 1
            fi
        elif is_valid_dataset "$arg"; then
            selected_datasets+=("$arg")
        else
            echo "Invalid dataset: $arg. Valid options are: ${valid_datasets[*]}"
            exit 1
        fi
    done
fi

# Function to calculate max heap size
calculate_max_heap_size() {
    # Detect the operating system
    OS_TYPE=$(uname)

    if [ "$OS_TYPE" == "Darwin" ]; then
        # macOS: Get total memory in bytes
        total_mem_bytes=$(sysctl -n hw.memsize)
    elif [ "$OS_TYPE" == "Linux" ]; then
        # Linux: Get total memory in kilobytes and convert to bytes
        total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        total_mem_bytes=$((total_mem_kb * 1024))
    else
        echo "Unsupported operating system: $OS_TYPE"
        exit 1
    fi

    # Calculate the thresholds
    threshold_bytes=$((total_mem_bytes * MAX_HEAP_THRESHOLD_PERCENT / 100))
    buffer_bytes=$((NON_HEAP_MEMORY_BUFFER_GB * 1024 * 1024 * 1024))

    # Calculate total memory minus buffer
    minus_buffer_bytes=$((total_mem_bytes - buffer_bytes))

    # Determine the greater value
    if [ "$threshold_bytes" -gt "$minus_buffer_bytes" ]; then
        max_heap_bytes=$threshold_bytes
    else
        max_heap_bytes=$minus_buffer_bytes
    fi

    # Ensure the max heap size is not negative or zero
    if [ "$max_heap_bytes" -le 0 ]; then
        echo "Error: Calculated Java heap size is non-positive."
        exit 1
    fi

    # Convert bytes to megabytes for the -Xmx parameter
    max_heap_mb=$((max_heap_bytes / (1024 * 1024)))

    # Return the max heap size in the format expected by Java
    echo "${max_heap_mb}m"
}

# Calculate the maximum heap size
MAX_HEAP_SIZE=$(calculate_max_heap_size)
echo "Setting Java maximum heap size to: $MAX_HEAP_SIZE"

# Arrays to store durations
import_durations=()
indexing_durations=()
total_durations=()

# Function to process each dataset
process_dataset() {
    local dataset="$1"

    # Determine the base dataset and suffix
    if [[ "$dataset" =~ ^([A-Z]{2})-([0-9]{4}-[0-9]{2}-[0-9]{2}.*)$ ]]; then
        base_dataset="${BASH_REMATCH[1]}"
        dataset_suffix="${BASH_REMATCH[2]}"
        file="${SNAPSHOT_PATH/#\~/$HOME}/${dataset}.zip"
    else
        base_dataset="$dataset"
        dataset_suffix="$d"
        file="${SNAPSHOT_PATH/#\~/$HOME}/${base_dataset}-${dataset_suffix}.zip"
    fi

    # Ensure file path variables are expanded
    file=$(eval echo "$file")

    # Find the index of the dataset in the valid_datasets array
    local dataset_index=-1
    for i in "${!valid_datasets[@]}"; do
        if [[ "${valid_datasets[$i]}" == "$base_dataset" ]]; then
            dataset_index=$i
            break
        fi
    done

    # Check if the dataset was found
    if [[ $dataset_index -eq -1 ]]; then
        echo "Error: Dataset $base_dataset not found in valid_datasets."
        return 1
    fi

    # Adjust the URL for the correct suffix
    url="${dataset_urls[$dataset_index]}${COMMON_SNAPSHOT_URL_PATH}${base_dataset}-${dataset_suffix}.zip"

    # Check if the file exists; if not, download it
    if [[ ! -f "$file" ]]; then
        echo "File $file not found. Downloading..."
        curl -v -u "${dataset_auth[$dataset_index]}" --insecure "$url" --output "$file"
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to download $file."
            return 1
        fi
    else
        echo "File $file already exists. Skipping download."
    fi

    # Clean and build the project
    gradle cleanAll
    gradle build

    # Record start time for import
    local start_import=$(date +%s)

    # Load data in raw mode
    export LOAD_DELAY_INDEX_ON_CREATE=true
    java -server -Djava.awt.headless=true -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx"$MAX_HEAP_SIZE" -jar moqui.war load raw location="$file"
    unset LOAD_DELAY_INDEX_ON_CREATE

    # Record start time for indexing
    local start_indexing=$(date +%s)

    # Create indexes and foreign keys
    export LOAD_INIT_DATASOURCE_TABLES=true
    java -server -Djava.awt.headless=true -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx"$MAX_HEAP_SIZE" -jar moqui.war load raw types=none
    unset LOAD_INIT_DATASOURCE_TABLES

    # Record end time
    local end=$(date +%s)

    # Perform backups
    if [[ "$dataset" =~ ^[A-Z]{2}- ]]; then
        # Only perform the backup for the dataset with the suffix
        ./backupH2.sh "${dataset}"
    else
        # Perform both backups for standard datasets
        ./backupH2.sh "$base_dataset"
        ./backupH2.sh "${base_dataset}-${dataset_suffix}"
    fi

    # Calculate durations
    local import_duration=$((start_indexing - start_import))
    local indexing_duration=$((end - start_indexing))
    local total_duration=$((end - start_import))

    # Append durations to arrays
    import_durations+=("$import_duration")
    indexing_durations+=("$indexing_duration")
    total_durations+=("$total_duration")
}

# Process each selected dataset
for dataset in "${selected_datasets[@]}"; do
    echo "Processing dataset: $dataset"
    process_dataset "$dataset"
done

# Unset environment variables
unset scheduled_job_check_time

# Display the durations after processing all datasets
echo -e "\nExecution times:"
for i in "${!selected_datasets[@]}"; do
    dataset="${selected_datasets[$i]}"
    import_duration="${import_durations[$i]}"
    indexing_duration="${indexing_durations[$i]}"
    total_duration="${total_durations[$i]}"

    echo "$dataset Import Duration: $((import_duration / 60)) minutes and $((import_duration % 60)) seconds."
    echo "$dataset Indexing Duration: $((indexing_duration / 60)) minutes and $((indexing_duration % 60)) seconds."
    echo "$dataset Total Duration: $((total_duration / 60)) minutes and $((total_duration % 60)) seconds."
    echo ""
done
