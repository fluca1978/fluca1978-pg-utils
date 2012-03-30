DROP TYPE   t_magazine_hit;
CREATE TYPE t_magazine_hit as (title text, hit integer);

CREATE OR REPLACE FUNCTION max_hit_titles( titles integer )
RETURNS SETOF t_magazine_hit
AS
$BODY$
DECLARE
	-- function variable declaration
	current_row	     t_magazine_hit%rowtype;
BEGIN

	FOR current_row IN SELECT title, hit 
                           FROM   magazine
			   WHERE  hit > 0
			   AND    download_path IS NOT NULL
			   ORDER  BY hit DESC
			   LIMIT titles
			   LOOP

		RETURN NEXT current_row;
	END LOOP;
	

END;
$BODY$
LANGUAGE plpgsql;