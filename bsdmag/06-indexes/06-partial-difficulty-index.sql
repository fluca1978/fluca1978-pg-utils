UPDATE pg_index SET indisvalid = false WHERE indexrelid = 'idx_difficulty'::regclass;



CREATE INDEX idx_difficulty_avg 
ON articles(difficulty)
WHERE difficulty = 'AVG';

VACUUM FULL ANALYZE articles;


SELECT relname, reltuples, relpages                                  
FROM pg_class 
WHERE relname = 'idx_difficulty_avg' AND relkind = 'i';

