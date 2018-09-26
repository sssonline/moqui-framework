gradle cleanDb
cp -R ~/src/MoquiBackup/MoquiH2Backup/backup$1/db/derby runtime/db/
cp -R ~/src/MoquiBackup/MoquiH2Backup/backup$1/db/h2 runtime/db/
cp -R ~/src/MoquiBackup/MoquiH2Backup/backup$1/db/orientdb runtime/db/
cp -R ~/src/MoquiBackup/MoquiH2Backup/backup$1/elasticsearch runtime/
