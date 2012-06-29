\timing
CREATE INDEX idx_listings ON articles(listings);
VACUUM FULL ANALYZE;
EXPLAIN SELECT title, pages, listings
FROM articles WHERE difficulty = 'AVG'
AND  listings > 0;
