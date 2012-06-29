CREATE INDEX idx_listings
ON articles(listings);

VACUUM FULL ANALYZE;

EXPLAIN SELECT title, abstract 
FROM articles
WHERE listings = 5;