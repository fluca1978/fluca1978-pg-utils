CREATE OR REPLACE FUNCTION max_hit_title()
RETURNS text
AS
$BODY$
DECLARE
	-- function variable declaration
        found_title    text;
BEGIN

	SELECT title
	INTO   found_title
	FROM   magazine
	WHERE  download_path IS NOT NULL
	AND    hit > 0
	ORDER  BY hit DESC
	LIMIT  1;

	RETURN found_title;

END;
$BODY$
LANGUAGE plpgsql;