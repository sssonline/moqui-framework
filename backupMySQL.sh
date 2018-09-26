mkdir -p ~/src/MoquiBackup/MoquiMySQLBackup
echo "DROP DATABASE IF EXISTS moqui; CREATE DATABASE moqui; GRANT ALL PRIVILEGES ON *.* TO 'moquiJoeUser'@'%';" > ~/src/MoquiBackup/MoquiMySQLBackup/backup$1.sql
mysqldump -A -R -E --triggers --single-transaction >> ~/src/MoquiBackup/MoquiMySQLBackup/backup$1.sql
