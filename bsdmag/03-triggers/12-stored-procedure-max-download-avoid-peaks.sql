CREATE OR REPLACE FUNCTION max_hit_title_without_peak( peak_distance integer )
RETURNS text
AS
$BODY$
DECLARE
	-- function variable declaration
        found_title    text;
	average_hit    integer;
BEGIN


	-- get the average download hit
	SELECT avg( hit )::integer
	INTO   average_hit
	FROM   magazine
	WHERE  download_path IS NOT NULL
	AND    hit > 0;


	-- select the max downloaded magazine
	-- avoiding those that are too much 
	-- distant from the average
	SELECT title
	INTO   found_title
	FROM   magazine
	WHERE  download_path IS NOT NULL
	AND    hit > 0
	AND    hit <= ( average_hit + peak_distance )
	ORDER  BY hit DESC
	LIMIT  1;

	RETURN found_title;

END;
$BODY$
LANGUAGE plpgsql;