CREATE OR REPLACE FUNCTION get_magazines_and_readers() 
RETURNS SETOF refcursor
AS $BODY$

DECLARE
	magazines_refcursor	refcursor;
	readers_refcursor	refcursor;

BEGIN
	RAISE INFO 'Opening cursor for the magazine table';
	OPEN magazines_refcursor FOR  SELECT * FROM magazine;
	RETURN NEXT magazines_refcursor;

	RAISE INFO 'Opening cursor for the readers table';
	OPEN readers_refcursor FOR  SELECT * FROM readers;
	RETURN NEXT readers_refcursor;


	RAISE INFO 'To use open a transaction and fetch all the tuples';
	RAISE INFO 'from the named cursor (the system will provide a';
	RAISE INFO '<unnamed portal 1> and so on name for each cursor:';
	RAISE INFO 'BEGIN;';
	RAISE INFO 'SELECT get_magazines_and_readers();';
	RAISE INFO 'FETCH ALL IN "<unnamed portal 1>";';
	RAISE INFO 'END;'; 


	RETURN;
END;

$BODY$ 
LANGUAGE plpgsql;