/**
  * Check all the roles to see the privileges and try to understand
  * if a role can be used to do a physical backup.
  * This creates a view that exports a set of flags that can be used to understand
  * the status of a role.
  *
  * Use `pg_has_role` with 'USAGE' instead of 'MEMBER' to see if the role can
  * access the privileges directly, not via a SET ROLE.
  *
  * Example of invocation:

    backupdb=> select * from vw_role_backup_privileges
               WHERE rolname IN ( 'luca', 'backup' );
  -[ RECORD 1 ]------------+-------
  rolname                  | backup
  can_do_backup            | t
  can_monitor_backup       | t
  can_create_restore_point | t
  can_switch_wal           | t
  -[ RECORD 2 ]------------+-------
  rolname                  | luca
  can_do_backup            | f
  can_monitor_backup       | f
  can_create_restore_point | f
  can_switch_wal           | f
  */


CREATE OR REPLACE VIEW vw_role_backup_privileges
AS
WITH flags AS (
    SELECT
    a.rolname
    , a.rolsuper         AS is_superuser
    , a.rolreplication AS can_start_replication
    , pg_has_role( a.rolname, 'pg_monitor', 'USAGE' ) AS pg_monitor
    , pg_has_role( a.rolname, 'pg_read_all_settings', 'USAGE' ) as pg_read_all_settings
    , pg_has_role( a.rolname, 'pg_read_all_stats', 'USAGE' ) as pg_read_all_stats
    , has_function_privilege( a.rolname, 'pg_start_backup( text, bool, bool )', 'EXECUTE' ) as pg_start_backup
    , has_function_privilege( a.rolname, 'pg_stop_backup( bool, bool )', 'EXECUTE' ) as pg_stop_backup
    , has_function_privilege( a.rolname, 'pg_stop_backup()', 'EXECUTE' ) as pg_stop_backup_exclusive
    , has_function_privilege( a.rolname, 'pg_create_restore_point( text )', 'EXECUTE' ) as pg_create_restore_point
    , has_function_privilege( a.rolname, 'pg_is_in_backup()', 'EXECUTE' ) as pg_is_in_backup
    , has_function_privilege( a.rolname, 'pg_switch_wal()', 'EXECUTE' ) as pg_switch_wal
FROM
    -- use pg_roles instead of pg_authid
    -- to allow non-superuser roles to query
    pg_roles a
)
SELECT f.rolname
    , f.is_superuser
      OR (
          f.can_start_replication
          AND f.pg_start_backup
          AND ( f.pg_stop_backup OR f.pg_stop_backup_exclusive )
      ) AS can_do_backup
    ,   f.pg_monitor
        OR ( f.pg_read_all_settings
             AND f.pg_read_all_stats
             AND f.pg_is_in_backup
        ) AS can_monitor_backup
    , f.pg_create_restore_point AS can_create_restore_point
    , f.pg_switch_wal           AS can_switch_wal
FROM flags f;
