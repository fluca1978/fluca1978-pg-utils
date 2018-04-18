BEGIN;

CREATE SCHEMA IF NOT EXISTS cf;

CREATE OR REPLACE FUNCTION cf.cf_date( birth_date date,
                                       male boolean DEFAULT true )
RETURNS char(5)
AS $CODE$
DECLARE
   y int;  -- year
   m int;  -- month (1-12)
   d int;  -- day
   month_decode char[] := ARRAY[ 'a'   -- january
                                 , 'b' -- february
                                 , 'c' -- march
                                 , 'd' -- april
                                 , 'e' -- may
                                 , 'h' -- june
                                 , 'l' -- july
                                 , 'm' -- august
                                 , 'p' -- september
                                 , 'r' -- october
                                 , 's' -- november
                                 , 't' -- december
                               ]::char[];

BEGIN
  -- get the year, last two digits
  y := to_char( birth_date, 'yy' );
  -- get the month index
  m := EXTRACT( month FROM birth_date );
  -- get the day
  d := EXTRACT( day FROM birth_date );

  -- if this is for a female, add
  -- a number to the day
  IF NOT male THEN
    d := d + 40;
  END IF;

  RAISE DEBUG 'cf_date: % -> % % [%] % ',
                          birth_date,
                          y,
                          m,
                          month_decode[m],
                          d;


  -- compose and return the string
  RETURN lpad( y::text, 2, '0' )
            || upper( month_decode[m] )
            || lpad( d::text, 2, '0' );
END
$CODE$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION cf.cf_letters( subject text )
RETURNS char(3)
AS $BODY$
DECLARE
  missing_chars int := 0;
  vowels text;
  consonants text;
  final_chars char(3);
BEGIN
  -- work always uppercase, avoid case-sensitiveness
  subject := upper( trim( subject ) );
  -- get all the consonants
  consonants := translate( subject, 'AEIOU', '' );
  -- extract all the vowels (negate consonants!)
  vowels := translate( subject, consonants, '' );

  RAISE DEBUG 'cf_letters: [%] -> [%] + [%]',
                             subject,
                             consonants,
                             vowels;

  IF length( consonants ) >= 3 THEN
     final_chars := substring( consonants FROM 1 FOR 3 );
  ELSE
     missing_chars := 3 - length( consonants );
     RAISE DEBUG 'Pushing % vowel(s)', missing_chars;
     final_chars := consonants || substring( vowels FROM 1 FOR  missing_chars );
  END IF;

  RETURN final_chars;
END
$BODY$
LANGUAGE plpgsql;


COMMIT;
