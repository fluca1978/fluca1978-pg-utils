TRUNCATE TABLE articles;

SELECT populate_articles_table_avg( 2000000 );

VACUUM FULL ANALYZE articles;

SELECT relname, reltuples, relpages 
FROM pg_class WHERE relname like 'articles%' AND relkind = 'r';

SELECT tablename, attname, n_distinct, most_common_vals, most_common_freqs
FROM pg_stats WHERE tablename = 'articles' AND attname = 'difficulty';

SELECT relname, reltuples, relpages
FROM pg_class WHERE relname like 'articles%' AND relkind = 'r';