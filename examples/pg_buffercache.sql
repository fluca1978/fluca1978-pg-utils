/*
 * Get overall information about memory
 */
WITH sb AS (
     SELECT setting::bigint FROM pg_settings
     WHERE name = 'shared_buffers'
)
SELECT
  pg_size_pretty( count(b.*)
                  * current_setting( 'block_size' )::bigint )
                  AS memory_in_use
  , round( count( b.* )
           / sb.setting::numeric
           * 100, 2 ) || ' %' AS in_use_percent
  , round( sum( count( b.* ) ) OVER w / sb.setting::numeric * 100, 2 ) || ' %' AS cumulative

  , CASE b.usagecount
       WHEN 0 THEN 'VERY VERY LOW'
       WHEN 1 THEN 'VERY LOW'
       WHEN 2 THEN 'LOW'
       WHEN 3 THEN 'MID'
       WHEN 4 THEN 'HIGH'
       WHEN 5 THEN 'VERY HIGH'
       WHEN 6 THEN 'VERY VERY HIGH'
       ELSE '-free-'
    END AS usage
FROM pg_buffercache b, sb
GROUP BY b.usagecount, sb.setting
WINDOW w AS ( ORDER BY b.usagecount DESC
           RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )

           ORDER BY b.usagecount DESC
;


/*
 * get detailed information about a relation
 */


/*
 * Get details about single relations
 */
WITH sb AS (
     SELECT setting::bigint FROM pg_settings
     WHERE name = 'shared_buffers'
)
SELECT
  c.relname
  , pg_size_pretty( count( b.* ) * current_setting( 'block_size' )::bigint ) AS in_memory
  , pg_size_pretty( c.relpages * current_setting( 'block_size' )::bigint ) AS on_disk
  , round( count( b.* ) / c.relpages::numeric * 100, 2 ) || ' %' AS cached
  , round( count( b.* )
            / sb.setting::numeric
            * 100, 2 ) || ' %' AS memory_consumption

FROM sb, pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode( c.oid )
WHERE
 b.reldatabase = ( SELECT oid FROM pg_database
                     WHERE datname = current_database() )
AND  c.relnamespace NOT IN ( SELECT oid FROM pg_namespace
                             WHERE nspname IN ( 'information_schema', 'pg_catalog' ) )
AND c.relname NOT LIKE 'pg_%'
AND c.relkind = 'r'
GROUP BY c.relname, sb.setting, c.relpages
ORDER BY memory_consumption DESC;



/**
 * Summary for table
 */
WITH sb AS (
SELECT setting::bigint FROM pg_settings
WHERE name = 'shared_buffers'
)
SELECT
   c.relname,
   count( b.* ) AS buffers
   , pg_size_pretty( count( b.* ) * current_setting( 'block_size' )::bigint ) AS in_memory
   , pg_size_pretty( c.relpages * current_setting( 'block_size' )::bigint ) AS on_disk
   , round( count( b.* ) / c.relpages::numeric * 100, 2 ) || ' %' AS cached
   , round( count( b.* )
      / sb.setting::numeric
      * 100, 2 ) || ' %' AS memory_consumption
FROM sb, pg_buffercache b INNER JOIN pg_class c
ON b.relfilenode = pg_relation_filenode(c.oid)
AND b.reldatabase IN (0, (SELECT oid FROM pg_database
                          WHERE datname = current_database()))
AND c.relkind = 'r'
AND  c.relnamespace NOT IN ( SELECT oid FROM pg_namespace
WHERE nspname IN ( 'information_schema', 'pg_catalog' ) )
AND c.relname NOT LIKE 'pg_%'
GROUP BY c.relname, c.relpages, sb.setting;






/*
 * Detailed view of all tables and buffers
 */
SELECT format( '%I.%I', n.nspname, c.relname ) AS table_name
, bf.usagecount
, pg_size_pretty( pg_table_size( c.oid::regclass ) ) AS size_on_disk
, pg_size_pretty( count(bf.*)
* current_setting( 'block_size' )::integer ) AS size_in_memory
, round( count(bf.*)
* current_setting( 'block_size' )::integer
* 100 / pg_table_size( c.oid::regclass ), 2 ) AS shared_percent
, round( count( bf.* )
*  100 / ( SELECT setting::integer
FROM pg_settings
WHERE name = 'shared_buffers'  ), 2 ) AS shared_overall
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_buffercache bf ON bf.relfilenode = pg_relation_filenode( c.oid )
WHERE n.nspname NOT IN ( 'pg_catalog', 'information_schema' )
AND bf.usagecount >= 3
GROUP BY n.nspname, c.relname, c.oid, bf.usagecount
ORDER BY bf.usagecount DESC, 1;
