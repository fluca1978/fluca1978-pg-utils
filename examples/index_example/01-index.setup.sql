-- load variables
\i 00-index.include.psql

BEGIN;

CREATE TABLE IF NOT EXISTS :example_table_name
(
	pk serial PRIMARY KEY,
	file_name text NOT NULL,
	file_size bigint DEFAULT :min_file_size,
	file_type text DEFAULT 'jpg',
	file_date date DEFAULT CURRENT_DATE,

	UNIQUE( file_name, file_type )
);

ALTER TABLE pictures SET ( autovacuum_enabled = false );


-- this always resets pg_class,relpages
-- and pg_class.reltuples
TRUNCATE TABLE :example_table_name;


INSERT INTO :example_table_name( file_name, file_size, file_type, file_date )
SELECT 'DSC-' || v
      , ( 1000 * v )::int % :min_file_size + :min_file_size
      , CASE v % 2 WHEN 0 THEN 'png'
       	           ELSE 'jpg'
        END
     , CURRENT_DATE - ( v * random() * 3650 )::int
FROM
     generate_series( 1, :initial_tuple_load ) v
;


-- create indexes after the tuple insertion to prevent
-- some wrong counting on statistics (pg_stat_user_indexes )
CREATE INDEX IF NOT EXISTS idx_file_size
ON :example_table_name( file_size );

CREATE INDEX IF NOT EXISTS id_month
ON :example_table_name( EXTRACT( month FROM file_date ) );



COMMIT;


-- show some stats
\i index.stats.sql
