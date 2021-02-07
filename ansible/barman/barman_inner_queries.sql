 SELECT pg_is_in_recovery();
 SELECT version();
 SELECT count(*) FROM pg_extension WHERE extname = 'pgespresso';
 SELECT pg_is_in_recovery();
 SELECT location, (pg_walfile_name_offset(location)).*, CURRENT_TIMESTAMP AS timestamp FROM pg_current_wal_lsn() AS location;
                SELECT
                  usesuper
                  OR
                  (
                    userepl
                    AND
                    (
                      pg_has_role(CURRENT_USER, 'pg_monitor', 'MEMBER')
                      OR
                      (
                        pg_has_role(CURRENT_USER, 'pg_read_all_settings', 'MEMBER')
                        AND pg_has_role(CURRENT_USER, 'pg_read_all_stats', 'MEMBER')
                      )
                    )
                    AND has_function_privilege(
                      CURRENT_USER, 'pg_start_backup(text,bool,bool)', 'EXECUTE')
                    AND
                    (
                      has_function_privilege(
                        CURRENT_USER, 'pg_stop_backup()', 'EXECUTE')
                      OR has_function_privilege(
                        CURRENT_USER, 'pg_stop_backup(bool,bool)', 'EXECUTE')
                    )
                    AND has_function_privilege(
                      CURRENT_USER, 'pg_switch_wal()', 'EXECUTE')
                    AND has_function_privilege(
                      CURRENT_USER, 'pg_create_restore_point(text)', 'EXECUTE')
                  )
                FROM
                  pg_user
                WHERE
                  usename = CURRENT_USER;
                
SELECT setting FROM pg_settings WHERE name='archive_timeout';
SELECT setting FROM pg_settings WHERE name='checkpoint_timeout';
SELECT setting FROM pg_settings WHERE name='wal_segment_size';
SELECT name, setting FROM pg_settings WHERE name IN ('config_file', 'hba_file', 'ident_file');
SELECT DISTINCT sourcefile AS included_file FROM pg_settings WHERE sourcefile IS NOT NULL AND sourcefile NOT IN (SELECT setting FROM pg_settings WHERE name = 'config_file') ORDER BY 1;
SELECT slot_name, active, restart_lsn FROM pg_replication_slots WHERE slot_type = 'physical' AND slot_name = 'barman_slot';
SHOW "synchronous_standby_names";
SELECT system_identifier::text FROM pg_control_system();
SELECT version();
SHOW "archive_mode";
SHOW "archive_command";
SELECT *, current_setting('archive_mode') IN ('on', 'always') AND (last_failed_wal IS NULL OR last_failed_wal LIKE '%.history' AND substring(last_failed_wal from 1 for 8) <= substring(last_archived_wal from 1 for 8) OR last_failed_time <= last_archived_time) AS is_archiving, CAST (archived_count AS NUMERIC) / EXTRACT (EPOCH FROM age(now(), stats_reset)) AS current_archived_wals_per_second FROM pg_stat_archiver;
SELECT spcname, oid, pg_tablespace_location(oid) AS spclocation FROM pg_tablespace WHERE pg_tablespace_location(oid) != '';
SHOW "wal_level";
SHOW "hot_standby";
SHOW "max_wal_senders";
SHOW "wal_keep_segments";
SHOW "data_checksums";
SHOW "max_replication_slots";
SHOW "wal_compression";
SELECT usesuper FROM pg_user WHERE usename = CURRENT_USER;
