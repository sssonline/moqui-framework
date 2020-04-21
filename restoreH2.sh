backup_root=~/src/MoquiBackup/MoquiH2Backup
moqui_root=~/src/moqui
gradle cleanDb
cp -R ${backup_root}/backup$1/db/derby ${moqui_root}/runtime/db/
cp -R ${backup_root}/backup$1/db/h2 ${moqui_root}/runtime/db/
cp -R ${backup_root}/backup$1/db/orientdb ${moqui_root}/runtime/db/
cp -R ${backup_root}/backup$1/elasticsearch ${moqui_root}/runtime/
