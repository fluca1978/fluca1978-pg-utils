
/**
 * A simple implementation of a 'shift'like function
 * to manage PostgreSQL arrays.
 *
 * @param a the array to shift
 * @param loops how many elements to remove
 * @param emit_intermediate true if you want to get the intermediate results
 * @returns a table with the removed element at the current step and
 *          the resulting array
 */
CREATE OR REPLACE FUNCTION
shift( a anyarray,
       loops int default 1,
       emit_intermediate boolean default false )
RETURNS TABLE( head text, tail anyarray, step int )
AS $CODE$
BEGIN
	-- check that the array is good and has
	-- at least one element
	IF a IS NULL OR array_length( a, 1 ) < 1 THEN
	   RETURN;
	END IF;

	-- if the array has less elements that those
	-- to shift, do only the max available shifting
	IF loops > array_length( a, 1 ) THEN
	   loops := array_length( a, 1 );
	END IF;

	-- initialize the returning array and the
	-- number of steps
	tail := a;
	step := 1;

	WHILE loops > 0 LOOP
		head := tail[ 1 ];
		tail := tail[ 2 : array_length( tail, 1 ) ];

		IF emit_intermediate OR loops = 1 THEN
		   RETURN NEXT;
		END IF;

		loops := loops - 1;
		step  := step + 1;
	END LOOP;

	RETURN;
END
$CODE$
LANGUAGE plpgsql;


/*
 * Example of usage

DO LANGUAGE plpgsql $CODE$
DECLARE
	a text[];
	h text;
	I INT;
BEGIN
	a := array[ 'alfa', 'beta', 'gamma', 'delta' ];

	FOR i IN 1 .. 2 LOOP
		SELECT head, tail
		INTO h, a
		FROM shift( a );

		RAISE INFO 'Removed <%> = %', h, a;
	END LOOP;
END
$CODE$
;
*/






/**
 * A shift version that does not perform iterations.
 * It returns only the shifted array and the last removed
 * element.
 *
 * @param a array to shift
 * @param loops number of shifts to perform
 *
 * @return a single tuple with the last removed element and
 *         the resulting array
 */
CREATE OR REPLACE FUNCTION
shiftx( a anyarray,
        loops int default 1 )
RETURNS TABLE( head text, tail anyarray )
AS $CODE$
BEGIN
	-- check that the array is good and has
	-- at least one element
	IF a IS NULL OR array_length( a, 1 ) < 1 THEN
	   RETURN;
	END IF;

	-- if the array has less elements that those
	-- to shift, do only the max available shifting
	IF loops > array_length( a, 1 ) THEN
	   loops := array_length( a, 1 );
	END IF;

	-- initialize the returning array
	-- and the head of the last element
	head := a[ loops ];
	tail := a[ 1 + loops : array_length( a, 1 ) ];

	RETURN NEXT;
	RETURN;
END
$CODE$
LANGUAGE plpgsql;




/*
 * Example for performance analysis.
-- INFO:  Using shift for 5000 iteration over 2505 elements = 00:05:40.513576
-- INFO:  Using shiftx for 5000 iteration over 2505 elements = 00:00:00.078997
-- DO
-- Time: 340597,743 ms (05:40,598)
*/

/*
DO LANGUAGE plpgsql
$CODE$
DECLARE
	a text[];
	ts_begin timestamp;
	ts_end   timestamp;
	iter     int;
	i        int;
BEGIN

	iter := 5000;

	-- initialize the array
	ts_begin := clock_timestamp();
	SELECT '{' || string_agg( v::text, ',' ) || '}'
	INTO a
	FROM generate_series( 1, iter / 2 + 5 ) v;
	ts_end := clock_timestamp();

	RAISE INFO 'Array allocation = %', ( ts_end - ts_begin );

	ts_begin := clock_timestamp();
	FOR i IN 1 .. iter LOOP
	    PERFORM shift( a, iter / 2 );
	END LOOP;
	ts_end := clock_timestamp();

	RAISE INFO 'Using shift for % iteration over % elements = %',
	      	   iter,
		   array_length( a, 1 ),
		   ( ts_end - ts_begin );


	ts_begin := clock_timestamp();
	FOR i IN 1 .. iter LOOP
	    PERFORM shiftx( a, iter / 2 );
	END LOOP;
	ts_end := clock_timestamp();

	RAISE INFO 'Using shiftx for % iteration over % elements = %',
	      	   iter,
		   array_length( a, 1 ),
		   ( ts_end - ts_begin );


END
$CODE$;

*/
