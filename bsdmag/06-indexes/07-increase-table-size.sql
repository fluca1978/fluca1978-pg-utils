INSERT INTO articles(title, abstract, listings, pages, difficulty)
SELECT title, abstract, listings, pages, difficulty
FROM   articles
WHERE  difficulty <> 'AVG';

INSERT INTO articles(title, abstract, listings, pages, difficulty)
SELECT title, abstract, listings, pages, difficulty
FROM   articles
WHERE  difficulty <> 'AVG';

INSERT INTO articles(title, abstract, listings, pages, difficulty)
SELECT title, abstract, listings, pages, difficulty
FROM   articles
WHERE  difficulty <> 'AVG';

INSERT INTO articles(title, abstract, listings, pages, difficulty)
SELECT title, abstract, listings, pages, difficulty
FROM   articles
WHERE  difficulty <> 'AVG';

INSERT INTO articles(title, abstract, listings, pages, difficulty)
SELECT title, abstract, listings, pages, difficulty
FROM   articles
WHERE  difficulty <> 'AVG';

INSERT INTO articles(title, abstract, listings, pages, difficulty)
SELECT title, abstract, listings, pages, difficulty
FROM   articles
WHERE  difficulty <> 'AVG';



VACUUM FULL ANALYZE articles;

SELECT relname, reltuples, relpages                                             
FROM pg_class                                                                             WHERE relname = 'idx_difficulty_avg' AND relkind = 'i';

SELECT relname, reltuples, relpages                                  
FROM pg_class WHERE relname = 'idx_difficulty' AND relkind = 'i';


SELECT tablename, attname, n_distinct, most_common_vals, most_common_freqs      
FROM pg_stats WHERE tablename = 'articles' AND attname = 'difficulty'; 


SELECT relname, reltuples, relpages 
FROM pg_class WHERE relname like 'articles%' AND relkind = 'r';