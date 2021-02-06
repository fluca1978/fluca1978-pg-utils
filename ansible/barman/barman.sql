CREATE ROLE backup WITH REPLICATION LOGIN PASSWORD 'backup';

GRANT EXECUTE ON FUNCTION pg_start_backup(text, boolean, boolean) to backup;
GRANT EXECUTE ON FUNCTION pg_stop_backup() to backup;
GRANT EXECUTE ON FUNCTION pg_stop_backup(boolean, boolean) to backup;
GRANT EXECUTE ON FUNCTION pg_switch_wal() to backup;
GRANT EXECUTE ON FUNCTION pg_create_restore_point(text) to backup;
GRANT pg_read_all_settings TO backup;
GRANT pg_read_all_stats TO backup;
