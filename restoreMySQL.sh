if [ -r  ~/src/MoquiBackup/MoquiMySQLBackup/backup.sql -a -f ~/src/MoquiBackup/MoquiMySQLBackup/backup.sql ]
then
mysql -u root -pmoqui1! < ~/src/MoquiBackup/MoquiMySQLBackup/backup.sql
else
echo 'No backup found to restore.'
fi
