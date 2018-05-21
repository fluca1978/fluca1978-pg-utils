-- load variables
\i 00-index.include.psql

-- suppress \ commands
\set QUIET 1

\pset expanded on
\pset title 'ITEMS'

SELECT
	count(*) AS total_tuples
	, count(*) FILTER ( WHERE file_type = 'jpg' ) AS jpg
	, count(*) FILTER ( WHERE file_type = 'png' ) AS png
	, min( EXTRACT( month FROM file_date ) ) AS min_file_month
	, count(*) FILTER ( WHERE EXTRACT( month FROM file_date ) =
	                            ( SELECT EXTRACT( month FROM file_date )
				      FROM pictures
				      OFFSET :item_number
				      LIMIT 1 ) )
	                   AS count_min_file_month
	, min( file_size ) AS min_file_size
	, count(*) FILTER ( WHERE file_size =
	                           ( SELECT file_size
				     FROM pictures
				     OFFSET :item_number
				     LIMIT 1 ) )
	                   AS count_min_file_size
FROM
	:example_table_name
;	

\pset expanded off




\pset title 'STATS'
\pset expanded on

SELECT
	c.relname
	, c.reltuples
	, c.relpages
	, ( c.relpages * 8 * 1024 ) || ' bytes' AS estimated_disk_size
	, pg_size_pretty( pg_relation_size( c.relname::regclass ) ) AS effective_disk_size
	, pg_relation_filepath( c.relname::regclass )
	, autoanalyze_count AS autoanalyze
	, analyze_count AS analyze
FROM
	pg_class c
JOIN
	pg_stat_user_tables sut
ON
	sut.relname = c.relname
WHERE
	c.relname = :'example_table_name'
AND
	c.relkind = 'r'
;

\pset expanded off




\pset title 'INDEXES'

SELECT
	relname
	, indexrelname
	, idx_scan
FROM
	pg_stat_user_indexes
WHERE
	relname = :'example_table_name'
;

-- unset the title
\pset title
