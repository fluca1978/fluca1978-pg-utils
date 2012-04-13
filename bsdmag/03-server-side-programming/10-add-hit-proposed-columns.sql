ALTER TABLE magazine ADD COLUMN hit integer DEFAULT 0;

UPDATE magazine SET hit = (random() * 100)::integer WHERE download_path IS NOT NUll;