-- load variables
\i 00-index.include.psql

BEGIN;



INSERT INTO :example_table_name( file_name, file_size, file_type, file_date )
SELECT 'DSC-UPGRADE-' || v
      , ( 1000 * v )::int % :min_file_size + :min_file_size
      , CASE v % 2 WHEN 0 THEN 'png'
       	           ELSE 'jpg'
        END
     , CURRENT_DATE - ( v * random() )::int
FROM
     generate_series( 1, :upgrade_tuple_load ) v
;


COMMIT;


-- show some stats
\i index.stats.sql
