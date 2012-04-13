CREATE OR REPLACE  RULE r_delete_magazine 
AS ON DELETE
TO magazine
DO INSTEAD
UPDATE magazine SET available = false, issuedon = NULL
WHERE  pk = OLD.pk;

