UPDATE pg_index SET indisvalid = true 
WHERE indexrelid = 'idx_difficulty'::regclass;


CLUSTER articles USING idx_difficulty;

