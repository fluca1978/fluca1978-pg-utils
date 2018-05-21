-- load variables
\i 00-index.include.psql


SELECT  mcv AS file_size_MCV, mcf
  FROM pg_stats,
   ROWS FROM ( unnest( most_common_vals::text::text[] ),
               unnest( most_common_freqs ) )
             r( mcv, mcf )
  WHERE tablename = :'example_table_name'
  AND attname = 'file_size'
  ORDER BY mcv
  LIMIT :item_number;



SELECT  mcv AS file_date_MCV, mcf
  FROM pg_stats,
   ROWS FROM ( unnest( most_common_vals::text::text[] ),
               unnest( most_common_freqs ) )
             r( mcv, mcf )
  WHERE tablename = :'example_table_name'
  AND attname = 'file_date'
  ORDER BY mcv
  LIMIT :item_number;


SELECT  mcv AS file_type_MCV, mcf
  FROM pg_stats,
   ROWS FROM ( unnest( most_common_vals::text::text[] ),
               unnest( most_common_freqs ) )
             r( mcv, mcf )
  WHERE tablename = :'example_table_name'
  AND attname = 'file_type'
  ORDER BY mcv
  LIMIT :item_number;
