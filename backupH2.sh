backup_root=~/src/MoquiBackup/MoquiH2Backup
moqui_root=~/src/moqui
rm -rf ${backup_root}/backup$1
mkdir -p ${backup_root}/backup$1/db
cp -R ${moqui_root}/runtime/db/derby ${backup_root}/backup$1/db
cp -R ${moqui_root}/runtime/db/h2 ${backup_root}/backup$1/db
cp -R ${moqui_root}/runtime/db/orientdb ${backup_root}/backup$1/db
cp -R ${moqui_root}/runtime/elasticsearch ${backup_root}/backup$1
