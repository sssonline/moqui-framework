mkdir -p ~/src/MoquiBackup/MoquiH2Backup
rm -rf ~/src/MoquiBackup/MoquiH2Backup/*
mkdir -p ~/src/MoquiBackup/MoquiH2Backup/db
cp -R runtime/db/derby ~/src/MoquiBackup/MoquiH2Backup/db
cp -R runtime/db/h2 ~/src/MoquiBackup/MoquiH2Backup/db
cp -R runtime/db/orientdb ~/src/MoquiBackup/MoquiH2Backup/db
cp -R runtime/elasticsearch ~/src/MoquiBackup/MoquiH2Backup
