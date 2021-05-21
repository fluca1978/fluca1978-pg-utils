
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
