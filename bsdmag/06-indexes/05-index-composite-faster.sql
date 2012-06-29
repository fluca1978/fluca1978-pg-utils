
-- drop previous indexes
DROP INDEX idx_listings;
DROP INDEX idx_difficulty;

DROP INDEX idx_difficulty_listings;
CREATE INDEX idx_difficulty_listings 
ON articles(listings, difficulty);

ALTER TABLE articles CLUSTER ON idx_difficulty_listings;
VACUUM FULL ANALYZE;

SELECT relname, reltuples, relpages FROM pg_class 
WHERE relname like '%idx_%';


EXPLAIN SELECT title, pages, listings
FROM articles WHERE (difficulty = 'AVG' OR difficulty = 'MIN' )
AND  listings > 0;
