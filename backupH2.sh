mkdir -p ~/src/MoquiBackup/MoquiH2Backup/backup$1
rm -rf ~/src/MoquiBackup/MoquiH2Backup/backup$1/*
mkdir -p ~/src/MoquiBackup/MoquiH2Backup/backup$1/db
cp -R runtime/db/derby ~/src/MoquiBackup/MoquiH2Backup/backup$1/db
cp -R runtime/db/h2 ~/src/MoquiBackup/MoquiH2Backup/backup$1/db
cp -R runtime/db/orientdb ~/src/MoquiBackup/MoquiH2Backup/backup$1/db
cp -R runtime/elasticsearch ~/src/MoquiBackup/MoquiH2Backup/backup$1
