/**
 * whoami.sql
 *
 * Creates a simple view 'whoami' that contains basic information about the running system,
 * user and so on.
 * Used to show how PostgreSQL provides introspection.
 */
CREATE OR REPLACE VIEW
whoami
AS
SELECT
  format( '%s (current) / %s (session)', CURRENT_USER, SESSION_USER ) AS user
  , current_schema() AS schema
  , current_database() AS database
  , current_schemas( true ) AS search_path
  , current_catalog AS catalog -- same as current_database()
  , CASE pg_my_temp_schema()
         WHEN 0 THEN NULL
         ELSE pg_my_temp_schema()
         END AS temp_schema -- 0 if not used
  , current_query() AS current_query
  , format( '%s:%s', inet_client_addr(), inet_client_port() ) AS connecting_from
  , format( '%s:%s', inet_server_addr(), inet_server_port() ) AS conneted_to
  , pg_backend_pid() AS PID
  , pg_blocking_pids( pg_backend_pid() ) AS blocked_by
  , now() - pg_postmaster_start_time() AS uptime
  , now() - pg_conf_load_time() AS configuration_loaded
;
