mysql -e "UPDATE performance_schema.setup_instruments SET enabled = 'YES' WHERE name = 'wait/lock/metadata/sql/mdl'; SELECT * FROM performance_schema.metadata_locks where LOCK_TYPE <> 'SHARED_READ';"
