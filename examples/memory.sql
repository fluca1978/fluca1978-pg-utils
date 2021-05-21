
/**
   * Converts a pg_buffercache.usagecount to a string value
   * usefult to display as a result.
   */
CREATE OR REPLACE FUNCTION
  f_usagecounter_to_string( uc int )
  RETURNS text
AS
  $CODE$
  SELECT CASE uc
         WHEN 0 THEN 'VERY VERY LOW'
         WHEN 1 THEN 'VERY LOW'
         WHEN 2 THEN 'LOW'
         WHEN 3 THEN 'MID'
         WHEN 4 THEN 'HIGH'
         WHEN 5 THEN 'VERY HIGH'
         WHEN 6 THEN 'VERY VERY HIGH'
         ELSE  '== FREE =='
    END || ' (' || coalesce(  uc::text, '!' ) || ')'
  $CODE$
    LANGUAGE sql;


  /**
   * Provides the name of a table and its type.
   */
  CREATE OR REPLACE FUNCTION
    f_tablename( 
       relname name
      , nspname name default 'public'
      , relkind char default 'r' )
    RETURNS text
  AS
    $CODE$
    DECLARE
    relation_type text;
  BEGIN
    SELECT CASE relkind
           WHEN 'r' THEN 'table'
           WHEN 'v' THEN 'view'
           WHEN 'm' THEN 'materialized'
           WHEN 's' THEN 'sequence'
           WHEN 'i' THEN 'index'
           END
      INTO relation_type;

    RETURN format( '(%s) %I.%I',
                  relation_type
                  , nspname
                  , relname );
    END
  $CODE$
  LANGUAGE plpgsql;


/**
   * Provides a kind of view about the overall memory usage.
   * Example of invocation:

   testdb=> select * from f_memory_usage();
   total_memory | memory  | percent | cumulative |    description    
   --------------+---------+---------+------------+-------------------
   256 MB       | 1464 kB | 0.56 %  | 0.56%      | VERY HIGH (5)
   256 MB       | 768 kB  | 0.29 %  | 0.85%      | HIGH (4)
   256 MB       | 6944 kB | 2.65 %  | 3.50%      | MID (3)
   256 MB       | 10 MB   | 4.09 %  | 7.59%      | LOW (2)
   256 MB       | 79 MB   | 31.01 % | 38.59%     | VERY LOW (1)
   256 MB       | 157 MB  | 61.41 % | 100.00%    | VERY VERY LOW (0)

   */
  CREATE OR REPLACE FUNCTION
    f_memory_usage()
    RETURNS
    TABLE( total_memory text, memory text, percent text, cumulative text, description text )
  AS
    $CODE$
    DECLARE
    shared_buffers bigint;
    block_size     int;
  BEGIN

    SELECT setting
      INTO shared_buffers
      FROM pg_settings
     WHERE name = 'shared_buffers';

    SELECT setting
      INTO block_size
      FROM pg_settings
     WHERE name = 'block_size';

    RETURN QUERY
      SELECT pg_size_pretty( block_size * shared_buffers ) as total_memory
      , pg_size_pretty( block_size  * count( bc.* ) ) as memory
           , round( count( bc.* )::numeric / shared_buffers * 100, 2 ) || ' %' as percent
           , round( sum( count( bc.* ) ) OVER w / shared_buffers::numeric * 100, 2 ) || '%' as cumulative
           , f_usagecounter_to_string( bc.usagecount )  as description 

                                      FROM pg_buffercache bc
                                      GROUP BY bc.usagecount
                                      WINDOW w AS (
                                        ORDER BY bc.usagecount DESC
                                        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                      )
                                      ORDER BY bc.usagecount DESC;
  END
    $CODE$
    LANGUAGE plpgsql;









/**
   * Provides a detailed view about the usage of every object in the current database.
   * Example of invocation:

   pgbench=# select * from f_memory_usage_by_table();
                                               FOODB
 total_memory | database |           relation            |   memory   | percent |    description    
--------------+----------+-------------------------------+------------+---------+-------------------
 256 MB       | pgbench  | pgbench_accounts (table)      | 608 kB     | 0.23 %  | MID (3)
 256 MB       | pgbench  | pgbench_accounts (table)      | 592 kB     | 0.23 %  | LOW (2)
 256 MB       | pgbench  | pgbench_accounts (table)      | 36 MB      | 14.13 % | VERY LOW (1)
 256 MB       | pgbench  | pgbench_accounts (table)      | 93 MB      | 36.19 % | VERY VERY LOW (0)
 256 MB       | pgbench  | pgbench_accounts_pkey (index) | 824 kB     | 0.31 %  | VERY HIGH (5)
 256 MB       | pgbench  | pgbench_accounts_pkey (index) | 280 kB     | 0.11 %  | HIGH (4)
 256 MB       | pgbench  | pgbench_accounts_pkey (index) | 2664 kB    | 1.02 %  | MID (3)
 256 MB       | pgbench  | pgbench_accounts_pkey (index) | 8880 kB    | 3.39 %  | LOW (2)
 256 MB       | pgbench  | pgbench_accounts_pkey (index) | 39 MB      | 15.25 % | VERY LOW (1)
 256 MB       | pgbench  | pgbench_accounts_pkey (index) | 51 MB      | 20.08 % | VERY VERY LOW (0)
 256 MB       | pgbench  | pgbench_branches (table)      | 16 kB      | 0.01 %  | MID (3)
 256 MB       | pgbench  | pgbench_branches (table)      | 8192 bytes | 0.00 %  | LOW (2)
 256 MB       | pgbench  | pgbench_branches (table)      | 16 kB      | 0.01 %  | VERY VERY LOW (0)
 256 MB       | pgbench  | pgbench_branches_pkey (index) | 8192 bytes | 0.00 %  | LOW (2)
 256 MB       | pgbench  | pgbench_history (table)       | 88 kB      | 0.03 %  | MID (3)
 256 MB       | pgbench  | pgbench_history (table)       | 8192 bytes | 0.00 %  | VERY LOW (1)
 256 MB       | pgbench  | pgbench_tellers (table)       | 88 kB      | 0.03 %  | MID (3)
 256 MB       | pgbench  | pgbench_tellers_pkey (index)  | 32 kB      | 0.01 %  | MID (3)
 256 MB       | pgbench  | pgbench_tellers_pkey (index)  | 8192 bytes | 0.00 %  | VERY VERY LOW (0)

   */
    CREATE OR REPLACE FUNCTION
    f_memory_usage_by_table()
    RETURNS
      TABLE( total_memory text, database text, relation text,
            memory text, percent text, description text )
  AS
    $CODE$
    DECLARE
    shared_buffers bigint;
    block_size     int;
  BEGIN

    SELECT setting
      INTO shared_buffers
      FROM pg_settings
     WHERE name = 'shared_buffers';

    SELECT setting
      INTO block_size
      FROM pg_settings
     WHERE name = 'block_size';

    RETURN QUERY
      SELECT pg_size_pretty( block_size * shared_buffers ) as total_memory
      , d.datname::text as database
      , f_tablename( c.relname, n.nspname, c.relkind::char ) as relation
      , pg_size_pretty( block_size  * count( bc.* ) ) as memory
      , round( count( bc.* )::numeric / shared_buffers * 100, 2 ) || ' %' as percent
      , f_usagecounter_to_string( bc.usagecount )  as description 

      FROM pg_buffercache bc
      -- every buffercache has information about the table on disk
      JOIN pg_class c ON bc.relfilenode = pg_relation_filenode( c.oid )
      -- also every buffer has a reference to the database
      JOIN pg_database d ON bc.reldatabase = d.oid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE
      -- skip the information schema
      c.relnamespace NOT IN ( SELECT oid FROM pg_namespace
                               WHERE nspname IN ( 'information_schema', 'pg_catalog' ) )
      -- skip every pg_ object
      AND c.relname NOT LIKE 'pg\_%'
      -- always stick to the current database
      AND d.datname = current_database()

      GROUP BY bc.usagecount, d.datname, c.relname, c.relkind, n.nspname
                                      WINDOW w AS (
                                        ORDER BY bc.usagecount DESC
                                        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                      )
      ORDER BY c.relname, bc.usagecount DESC;
  END
    $CODE$
    LANGUAGE plpgsql;


/**
   * Provides information about per-table usage.
   * It does not display any information about the memory usage, rather a cumulative
   * indication of the per-table usage and the amount of memory that is in cache.
   * Example of invocation:

pgbench=# select * from f_memory_usage_by_table_cumulative( 3 );
                                                                FOODB
 total_memory | database |           relation           | memory  | on_disk | percent_of_memory | percent_of_disk | usagedescription 
--------------+----------+------------------------------+---------+---------+-------------------+-----------------+------------------
 256 MB       | pgbench  | public.pgbench_accounts      | 608 kB  | 1281 MB | 0.23 %            | 0.05%           | >= MID (3)
 256 MB       | pgbench  | public.pgbench_accounts_pkey | 3768 kB | 214 MB  | 1.44 %            | 1.72%           | >= MID (3)
 256 MB       | pgbench  | public.pgbench_history       | 88 kB   | 104 kB  | 0.03 %            | 84.62%          | >= MID (3)
 256 MB       | pgbench  | public.pgbench_tellers       | 88 kB   | 88 kB   | 0.03 %            | 100.00%         | >= MID (3)
 256 MB       | pgbench  | public.pgbench_branches      | 16 kB   | 40 kB   | 0.01 %            | 40.00%          | >= MID (3)
 256 MB       | pgbench  | public.pgbench_tellers_pkey  | 32 kB   | 40 kB   | 0.01 %            | 80.00%          | >= MID (3)


   *
   * The integer argument specifies a value between 0 and 6 to get the correct level of
   * memory usage for the table. In the case NULL, or an out of range value is specified, the
   * value is automatically set to 0 that means 'every usage'.
*/

  CREATE OR REPLACE FUNCTION
    f_memory_usage_by_table_cumulative( wanted_usagecount int default 0 )
    RETURNS
    TABLE( total_memory text, database text, relation text,
          memory text, on_disk text,  percent_of_memory text, percent_of_disk text
    , usagedescription text )
  AS
    $CODE$
    DECLARE
    shared_buffers bigint;
    block_size     int;
  BEGIN

    SELECT setting
      INTO shared_buffers
      FROM pg_settings
     WHERE name = 'shared_buffers';

    SELECT setting
      INTO block_size
      FROM pg_settings
     WHERE name = 'block_size';

    -- normalize usage count value
    IF wanted_usagecount IS NULL OR wanted_usagecount < 0 THEN
      wanted_usagecount := 0;
    ELSEIF wanted_usagecount > 6 THEN
      wanted_usagecount := 6;
    END IF;

    RETURN QUERY
      SELECT
      pg_size_pretty( block_size * shared_buffers ) as total_memory
      , d.datname::text as database
      , f_tablename( c.relname, n.nspname, c.relkind::char ) as relation
      , pg_size_pretty( block_size  * count( bc.* ) ) as memory
      , pg_size_pretty( pg_table_size( c.oid::regclass ) ) AS on_disk
      , round( count( bc.* )::numeric / shared_buffers * 100, 2 ) || ' %' as percent_of_memory
      , round( count( bc.* )::numeric * block_size / pg_table_size( c.oid ) * 100, 2 ) || '%' as percent_of_disk 
      , CASE wanted_usagecount
      WHEN 0 THEN 'any'
      ELSE '>= ' || f_usagecounter_to_string( wanted_usagecount )
      END as usage_description 
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN pg_buffercache bc ON bc.relfilenode = pg_relation_filenode( c.oid )
      JOIN pg_database d ON d.oid = bc.reldatabase
      WHERE n.nspname NOT IN ( 'pg_catalog', 'information_schema' )
      AND c.relpages > 0 -- avoid empty tables!
      AND c.relname NOT LIKE 'pg\_%'
      AND bc.usagecount >= wanted_usagecount
      GROUP BY n.nspname, c.relname, c.oid, d.datname, c.relkind
      ORDER BY pg_table_size( c.oid ) DESC, 4;
  END
$CODE$
  LANGUAGE plpgsql;
