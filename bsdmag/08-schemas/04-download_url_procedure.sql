CREATE OR REPLACE FUNCTION bsdmag.download_url( magazine_pk integer )
RETURNS text
AS
$BODY$
DECLARE
	magazine_id	text;
BEGIN

	-- get the magazine id
	SELECT id
	INTO   magazine_id
	FROM   magazine
	WHERE  pk = magazine_pk;

	IF magazine_id IS NULL THEN
	   RETURN '';
	END IF;
	
	RAISE LOG 'bsdmag.download_url()';
	-- this is the part that changes depending on the schema
	RETURN 'http://bsdmag.org/download/' || magazine_id || '.pdf';	
	

END;
$BODY$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION linuxmag.download_url( magazine_pk integer )
RETURNS text
AS
$BODY$
DECLARE
	magazine_id	text;
BEGIN

	-- get the magazine id
	SELECT id
	INTO   magazine_id
	FROM   magazine
	WHERE  pk = magazine_pk;

	IF magazine_id IS NULL THEN
	   RETURN '';
	END IF;

	RAISE LOG 'linuxmag.download_url()';
	-- this is the part that changes depending on the schema
	RETURN 'http://linuxmag.org/download/' || magazine_id || '.pdf';	
	

END;
$BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pentestmag.download_url( magazine_pk integer )
RETURNS text
AS
$BODY$
DECLARE
	magazine_id	text;
BEGIN

	-- get the magazine id
	SELECT id
	INTO   magazine_id
	FROM   magazine
	WHERE  pk = magazine_pk;

	IF magazine_id IS NULL THEN
	   RETURN '';
	END IF;

	RAISE LOG 'pentestmag.download_url()';
	-- this is the part that changes depending on the schema
	RETURN 'http://pentestmag.org/download/' || magazine_id || '.pdf';	
	

END;
$BODY$
LANGUAGE plpgsql;


