--
-- A simple roman converter implemented in PL/PgSQL.
--

/*
 Example of usage:

 testdb=> select fluca1978.to_roman( 1978 );
DEBUG:  The value 1978 is greater than 1000 so appending a M
DEBUG:  The value 978 is greater than 900 so appending a CM
DEBUG:  The value 78 is greater than 50 so appending a L
DEBUG:  The value 28 is greater than 10 so appending a X
DEBUG:  The value 18 is greater than 10 so appending a X
DEBUG:  The value 8 is greater than 5 so appending a V
DEBUG:  The value 3 is greater than 1 so appending a I
DEBUG:  The value 2 is greater than 1 so appending a I
DEBUG:  The value 1 is greater than 1 so appending a I
DEBUG:  Computed value is MCMLXXVIII
  to_roman
------------
 MCMLXXVIII
(1 row)




testdb=> select fluca1978.from_roman( 'MCMLXXVIII' );
 from_roman
------------
       1978
(1 row)
*/


CREATE SCHEMA IF NOT EXISTS fluca1978;

DROP TABLE IF EXISTS fluca1978.roman;
CREATE  TABLE IF NOT EXISTS fluca1978.roman( r text, n int, repeatable boolean );

TRUNCATE TABLE fluca1978.roman;

INSERT INTO fluca1978.roman
VALUES
('I', 1, true )
,( 'IV', 4, false )
,( 'V', 5, false )
,( 'IX', 9, false )
,( 'X', 10, true )
,( 'XL', 40, false )
,( 'L', 50, false )
,( 'XC', 90, false )
,( 'C', 100, true )
,( 'CD', 400, false )
,( 'D', 500, false )
,( 'CM', 900, false )
,( 'M', 1000, true );




/*
 * Utility function to perform validation on an input Roman string.
 *
 * @param r the roman input string
 * @return true fi the string is valid
 */
CREATE OR REPLACE FUNCTION
fluca1978.validate_roman( r text )
RETURNS boolean
STRICT
AS $CODE$
DECLARE
	current_record fluca1978.roman%rowtype;
	rx text;
	matches int;
BEGIN

	r := upper( r );

	FOR current_record IN SELECT * FROM fluca1978.roman ORDER BY n DESC LOOP
	    RAISE DEBUG 'Iterating over Roman value % = %', current_record.r, current_record.n;

	    matches := 0;
	    rx := format( '^%s', current_record.r );

	    WHILE r ~ rx LOOP
	    	  matches := matches + 1;
		  RAISE DEBUG 'Input string % -> % matches the Roman value %', r, matches, current_record.r;

		  IF NOT current_record.repeatable AND matches > 1 THEN
		     RAISE DEBUG 'Roman symbol % cannot be repeated!', current_record.r;
		     RETURN false;
		  END IF;

		  r := regexp_replace( r, rx, '' );
		  EXIT WHEN length( r ) = 0;
	    END LOOP;

 	   EXIT WHEN length( r ) = 0;
	END LOOP;

	IF length( r ) > 0 THEN
	   RETURN false;
	END IF;

	RETURN true;
END
$CODE$
LANGUAGE plpgsql;




/*
 * Converts a string in roman format into an integer, or zero if the string is wrong.
 *
 * @param r the roman string
 * @return the integer value or zero on null or wrong input
 */
CREATE OR REPLACE FUNCTION
fluca1978.from_roman( r text )
RETURNS int
STRICT
AS $CODE$
DECLARE
	v int := 0;
	current_record fluca1978.roman%rowtype;
	rx text;
BEGIN
	IF r = '' THEN
	   RETURN 0;
	END IF;

	IF NOT fluca1978.validate_roman( r ) THEN
	   RETURN 0;
	END IF;

	FOR current_record IN SELECT * FROM fluca1978.roman ORDER BY n DESC LOOP
	     RAISE DEBUG 'Iterating over Roman value % = %', current_record.r, current_record.n;

	     rx := format( '^%s', current_record.r );
	    WHILE r ~ rx LOOP
		RAISE DEBUG 'Input string % matches the Roman value %', r, current_record.r;

	        v := v + current_record.n;
	        r := regexp_replace( r, rx, '' );
	    END LOOP;
	END LOOP;

	RAISE DEBUG 'Converted value is %', v;
	RETURN v;
END
$CODE$
LANGUAGE plpgsql;




/*
 * A function to convert an arabic number into roman.
 *
 * @param n the arabicnumber
 * @return the roman string
 */
CREATE OR REPLACE FUNCTION
fluca1978.to_roman( n int )
RETURNS text
STRICT
AS $CODE$

DECLARE
	roman_value text := '';
    current_record fluca1978.roman%rowtype;
BEGIN
	IF n <= 0 THEN
		RAISE DEBUG 'Cannot convert zero!';
		RETURN NULL;
	END IF;

	FOR current_record IN SELECT * FROM fluca1978.roman ORDER BY n DESC LOOP

	    WHILE n >= current_record.n LOOP
			RAISE DEBUG 'The value % is greater than % so appending a %', n, current_record.n, current_record.r;
			roman_value := roman_value || current_record.r;
			n := n - current_record.n;
			EXIT WHEN length( current_record.r ) = 2;
	    END LOOP;
	END LOOP;

	RAISE DEBUG 'Computed value is %', roman_value;
	RETURN roman_value;
END
$CODE$
LANGUAGE plpgsql;





/******************** CACHING ***************************************/


CREATE TABLE IF NOT EXISTS fluca1978.roman_cache_table( n int, r text );
TRUNCATE TABLE fluca1978.roman_cache_table;

INSERT INTO fluca1978.roman_cache_table( n, r )
SELECT n, r
FROM   fluca1978.roman
ORDER BY n;


CREATE OR REPLACE FUNCTION
fluca1978.roman_cache( x int )
RETURNS text
STRICT
AS $CODE$
DECLARE
	max_cached_value int;
	i int;
	v text;
BEGIN
	SELECT max( n )
	INTO max_cached_value
	FROM fluca1978.roman_cache_table;

	RAISE DEBUG 'Max cached value % and looking for %', max_cached_value, x;

	IF max_cached_value IS NULL OR x > max_cached_value THEN
	   IF max_cached_value IS NULL THEN
	      max_cached_value := 1;
	   END IF;
	   RAISE DEBUG 'Repopulating the cache from % to %', max_cached_value, x;

	   FOR i IN max_cached_value + 1 .. x LOOP
	   	   INSERT INTO fluca1978.roman_cache_table( n, r )
	   	   SELECT i, fluca1978.to_roman( i );
	   END LOOP;
	END IF;

	SELECT r
	INTO v
	FROM fluca1978.roman_cache_table
	WHERE n = x;

	RETURN v;
END
$CODE$
LANGUAGE plpgsql;



