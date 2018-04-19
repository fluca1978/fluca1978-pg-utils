/*
 + An example to compute an italian codice fiscale
 * using plpgsql functions.
 *
 * All functions and data is placed into a specific schema to not pollute
 * ordinary data.
 *
 * In order to see debug messages:
 *
 * set client_min_messages to debug;
 *
 * To check the whole generator invoke cf.cf() function.
 * See <https://it.wikipedia.org/wiki/Codice_fiscale>
 */


BEGIN;

CREATE SCHEMA IF NOT EXISTS cf;

 /**
  * Computes the date string for a specific birth date and
  * gender.
  * Example of invocation:
  * SELECT cf.cf_date( '1978-7-19', true );
  * which produces:
  * 78L19
  */
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


/**
 * Computes the sequence of three chars for a name and/or surname.
 */
CREATE OR REPLACE FUNCTION cf.cf_letters( subject text, is_name bool DEFAULT false )
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

  IF is_name THEN 
    IF length( consonants ) >= 4 THEN
       consonants := substring( consonants FROM 1 FOR 1 )
                        || substring( consonants FROM 3 FOR 1 )
                        || substring( consonants FROM 4 FOR 1 );
    ELSIF length( consonants ) = 3 THEN
      consonants := substring( consonants FROM 1 FOR 3 );
    END IF;
  END IF;

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


/**
 * Each birth-place has a specific code that has to be inserted into
 * the resulting string. In order to look up codes by place names,
 * use a simple table.
 */
CREATE TABLE IF NOT EXISTS cf.places( code char(4) PRIMARY KEY,
                                      description text NOT NULL,
                                      UNIQUE( description ),
                                      EXCLUDE( lower( trim( description ) ) WITH = ) );


TRUNCATE cf.places;

INSERT INTO cf.places( code, description )
VALUES
( 'F257', 'Modena' ),
( 'D711', 'Formigine' ),
( 'A944', 'Bologna' ),
( 'F357', 'Serramazzoni' );



/**
 * Translate a place name, case-insensitively, into
 * a code string. This is not a very strong alghoritm, since
 * it is based on text comparison...
 */
CREATE OR REPLACE FUNCTION cf.cf_place( birth_place text )
RETURNS char(4)
AS $CODE$
DECLARE
  birth_code char(4);
BEGIN
  SELECT code
  INTO birth_code  -- no strict! allow NOT FOUND to work!
  FROM cf.places
  WHERE lower( description ) = lower( birth_place );

  IF NOT FOUND THEN
     RAISE WARNING '% not in cf.places!', birth_place;
     RETURN 'XXXX';
  END IF;

  RETURN birth_code;
END
$CODE$
LANGUAGE plpgsql;


/**
 + In order to compute the checksum character
 * it is required to compute a sum based on the value of each
 * character and its position, odd or even.
 * This table contains all the values required to compute the sum.
 */
CREATE TABLE IF NOT EXISTS cf.check_chars( c char PRIMARY KEY,
                                           odd_value int NOT NULL,
                                           even_value int NOT NULL );
TRUNCATE TABLE cf.check_chars;

INSERT INTO cf.check_chars( c, odd_value, even_value )
VALUES
( '0', 1, 0 )
,( '1', 0, 1 )
,( '2', 5, 2 )
,( '3', 7, 3 )
,( '4', 9, 4 )
,( '5', 13, 5 )
,( '6', 15, 6 )
,( '7', 17, 7 )
,( '8', 19, 8 )
,( '9', 21, 9 )
,( 'A', 1, 0 )
,( 'B', 0, 1 )
,( 'C', 5, 2 )
,( 'D', 7, 3 )
,( 'E', 9, 4 )
,( 'F', 13, 5 )
,( 'G', 15, 6 )
,( 'H', 17, 7 )
,( 'I', 19, 8 )
,( 'J', 21, 9 )
,( 'K', 2, 10 )
,( 'L', 4 , 11 )
,( 'M', 18, 12 )
,( 'N', 20, 13 )
,( 'O', 11, 14 )
,( 'P', 3, 15 )
,( 'Q', 6, 16 )
,( 'R', 8, 17 )
,( 'S', 12, 18 )
,( 'T', 14, 19 )
,( 'U', 16, 20 )
,( 'V', 10, 21 )
,( 'W', 22, 22 )
,( 'X', 25, 23 )
,( 'Y', 24, 24 )
,( 'Z', 23, 25 );




/**
 + Compute the checksum character.
 */
CREATE OR REPLACE FUNCTION cf.cf_check( subject char(15) )
RETURNS char
AS $BODY$
DECLARE
  check_char char;
  odd_sum int := 0;
  even_sum int := 0;
  i int;
  current_value int;
  final_value int;
  odd_in text := '';
  even_in text := '';
  current_letter char;
BEGIN

  FOR i in 1..length( subject ) LOOP
      IF i % 2 = 0 THEN
         SELECT even_value
         INTO STRICT current_value
         FROM cf.check_chars
         WHERE c = upper( substring( subject FROM i FOR 1 ) );

         even_sum := even_sum + current_value;
      ELSE
        SELECT odd_value
        INTO STRICT current_value
        FROM cf.check_chars
        WHERE c = upper( substring( subject FROM i FOR 1 ) );

        odd_sum := odd_sum + current_value;
     END IF;
  END LOOP;



   final_value := ( odd_sum + even_sum ) % 26;
   RAISE DEBUG 'cf_check: % + % %% 26 = %', odd_sum, even_sum, final_value;

  -- this is a trick: the remaining part
  -- indicates the positional order of the letter
  -- within the alphabet, which is
  -- the values into the table excluding digits
  SELECT c
  INTO STRICT check_char
  FROM cf.check_chars
  WHERE even_value = final_value
  AND c NOT IN ( '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' );

  RETURN check_char;
END
$BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cf.cf( surname text,
                         name text,
                         birth_date date,
                         birth_place text,
                         gender bool DEFAULT true )
RETURNS char(16)
AS $CODE$
DECLARE
  cf_string char(15);
  cf_check  char(1);
BEGIN
  cf_string := cf.cf_letters( surname )
               || cf.cf_letters( name, true )
               || cf.cf_date( birth_date, gender )
               || cf.cf_place( birth_place );

   cf_check := cf.cf_check( cf_string );
   RAISE DEBUG 'cf: % + %', cf_string, cf_check;

  RETURN upper( cf_string || cf_check );
END
$CODE$
LANGUAGE plpgsql;

COMMIT;
