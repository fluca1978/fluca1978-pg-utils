SELECT populate_articles_table( 2000000 );
VACUUM FULL ANALYZE articles;

SELECT relname, reltuples, relpages 
FROM pg_class WHERE relname like 'articles%' AND relkind = 'r';