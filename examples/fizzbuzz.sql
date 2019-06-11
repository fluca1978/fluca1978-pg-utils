/*
Write a program that prints the numbers from 1 to 100. But for multiples of three print “Fizz” instead of the number and for the multiples of five print “Buzz”. For numbers which are multiples of both three and five print “FizzBuzz”.

See <http://wiki.c2.com/?FizzBuzzTest>
*/

CREATE OR REPLACE FUNCTION
fizzbuzz( start_number int DEFAULT 1, end_number int DEFAULT 100 )
RETURNS VOID
AS
$CODE$
DECLARE
  current_number int;
  current_value  text;
BEGIN
  -- check arguments
  IF start_number >= end_number THEN
     RAISE EXCEPTION 'The start number must be lower then the end one! From % to %', start_number, end_number;
  END IF;

  FOR current_number IN start_number .. end_number LOOP
      current_value := NULL;

      IF current_number % 3 = 0 THEN
         current_value := 'Fizz';
      END IF;
      IF current_number % 5 = 0 THEN
         current_value := current_value || 'Buzz';
      END IF;

      IF current_value IS NULL THEN
         current_value := current_number::text;
      END IF;

      RAISE INFO '% -> %', current_number, current_value;
  END LOOP;
END
$CODE$
LANGUAGE plpgsql;



WITH RECURSIVE n AS (
     SELECT 1 AS current_number, NULL AS mod_3, NULL AS mod_5
     UNION
     SELECT current_number + 1 as current_number
            , CASE ( current_number + 1 ) % 3 WHEN 0 THEN 'Fizz'
                                              ELSE NULL
                                              END AS mod_3
           , CASE ( current_number + 1 ) % 5 WHEN 0 THEN 'Buzz'
                                              ELSE NULL
                                              END AS mod_5
     FROM n WHERE current_number < 99
)
SELECT current_number, coalesce( mod_3 || mod_5, mod_3, mod_5, current_number::text )
FROM n;


/* porposed by Gábor Szabó */

SELECT
COALESCE(NULLIF(
CASE WHEN i % 3 = 0 THEN 'Fizz' ELSE '' END ||
CASE WHEN i % 5 = 0 THEN 'Buzz' ELSE '' END
, ''), i::TEXT)
FROM generate_series(1, 15) i;
