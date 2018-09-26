if [ -r  ~/src/MoquiBackup/MoquiMySQLBackup/backup$1.sql -a -f ~/src/MoquiBackup/MoquiMySQLBackup/backup$1.sql ]
then
mysql < ~/src/MoquiBackup/MoquiMySQLBackup/backup$1.sql
else
echo 'No backup found to restore.'
fi
