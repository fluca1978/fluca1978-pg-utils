/*
  * A didactical implementation of operator classes to add meaning to field
  * and be able to index them in a specific way.
  * Once the operator class is in place, it is possible to execute queries
  * to see different output.
  * The index can be created with something like

  CREATE INDEX idx_cf_test ON foo( cf cf_date_ops );

  * and then it is possible to see how the index returns different "natural" sorting.
  * Without the index (or with an ordinary index and enable_seqscan set to 'off'):
testdb=# select * from cf_test;
         cf
------------------
aaaaaa78l19f257b
bbbbbb78l19f257b
cccccc68p06f257k
(3 rows)

  * With the index in place:

testdb=# select * from cf_test;
         cf
------------------
cccccc68p06f257k
aaaaaa78l19f257b
bbbbbb78l19f257b
*/

/**
 * Extract the year of birth from an italian fiscal code
 */
CREATE OR REPLACE FUNCTION
extract_date_from_cf( cf text )
RETURNS date
AS
$CODE$
DECLARE
  month_decode char[] := ARRAY[ 'a' -- january
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
   _month int;
   _day   int;
   _year  int;
   i      int;
BEGIN
  IF length( cf ) < 16 THEN
     RETURN NULL;
  END IF;

  _year := substring( cf, 7, 2 )::int + 1900;
  _day  := substring( cf, 10, 2 )::int;

  -- women have the birth day grown by 40
  IF _day > 40 THEN
     _day := _day - 40;
  END IF;

  FOR i IN 1 .. array_length( month_decode, 1 ) LOOP
      RAISE DEBUG 'Inspecting month %', i;
      IF lower( substring( cf, 9, 1 ) ) = month_decode[ i ] THEN
         _month := i;
         EXIT;
      END IF;
  END LOOP;

  RAISE DEBUG 'Year = %, day = %, month = %', _year, _day, _month;

  RETURN make_date( _year, _month, _day );
END
$CODE$
LANGUAGE plpgsql
STRICT;


/**
 * --------------------------------------------
 *        EQUALITY FUNCTION AND OPERATOR
 * --------------------------------------------
 */
CREATE OR REPLACE FUNCTION
cf_eq( cf1 text, cf2 text )
RETURNS bool
AS $CODE$
BEGIN
   RETURN extract_date_from_cf( cf1 ) = extract_date_from_cf( cf2 );
END
$CODE$
LANGUAGE plpgsql;


CREATE OPERATOR ~~= (
       LEFTARG  = text,
       RIGHTARG = text,
       FUNCTION = cf_eq
);


/**
 * ----------------------------------------
 *    SAME FUNCTION used as support
 *    for internal operator class comparison
 * ----------------------------------------
 */
CREATE OR REPLACE FUNCTION
cf_compare( cf1 text, cf2 text )
RETURNS int
AS
$CODE$
DECLARE
  d1 date;
  d2 date;
BEGIN
  d1 := extract_date_from_cf( cf1 );
  d2 := extract_date_from_cf( cf2 );

  IF d1 > d2 THEN
     RETURN 1;
  ELSIF d1 < d2 THEN
    RETURN -1;
  ELSE
    RETURN 0;
  END IF;
END
$CODE$
LANGUAGE plpgsql;



/**
* --------------------------------------------
*        LESS-OR_EQUAL FUNCTION AND OPERATOR
* --------------------------------------------
*/
CREATE OR REPLACE FUNCTION
cf_le( cf1 text, cf2 text )
RETURNS bool
AS $CODE$
BEGIN
   RETURN extract_date_from_cf( cf1 ) <= extract_date_from_cf( cf2 );
END
$CODE$
LANGUAGE plpgsql;


CREATE OPERATOR ~<= (
LEFTARG  = text,
RIGHTARG = text,
FUNCTION = cf_le
);



/**
* --------------------------------------------
*        LESS-THEN FUNCTION AND OPERATOR
* --------------------------------------------
*/
CREATE OR REPLACE FUNCTION
cf_lt( cf1 text, cf2 text )
RETURNS bool
AS $CODE$
BEGIN
   RETURN extract_date_from_cf( cf1 ) < extract_date_from_cf( cf2 );
END
$CODE$
LANGUAGE plpgsql;


CREATE OPERATOR ~<< (
LEFTARG  = text,
RIGHTARG = text,
FUNCTION = cf_lt
);



/**
* --------------------------------------------
*        GREATER-THEN FUNCTION AND OPERATOR
* --------------------------------------------
*/
CREATE OR REPLACE FUNCTION
cf_gt( cf1 text, cf2 text )
RETURNS bool
AS $CODE$
BEGIN
  RETURN extract_date_from_cf( cf1 ) > extract_date_from_cf( cf2 );
END
$CODE$
LANGUAGE plpgsql;


CREATE OPERATOR ~>> (
LEFTARG  = text,
RIGHTARG = text,
FUNCTION = cf_gt
);


/**
* --------------------------------------------
*        GREATER-OR-EQUAL FUNCTION AND OPERATOR
* --------------------------------------------
*/
CREATE OR REPLACE FUNCTION
cf_ge( cf1 text, cf2 text )
RETURNS bool
AS $CODE$
BEGIN
   RETURN extract_date_from_cf( cf1 ) >= extract_date_from_cf( cf2 );
END
$CODE$
LANGUAGE plpgsql;


CREATE OPERATOR ~>= (
LEFTARG  = text,
RIGHTARG = text,
FUNCTION = cf_ge
);



/**
 * ---------------------------------------------
 *     OPERATOR CLASS
 * ---------------------------------------------
 */
CREATE OPERATOR CLASS
cf_date_ops
FOR TYPE TEXT USING BTREE
AS
  OPERATOR 1 ~<<,
  OPERATOR 2 ~<=,
  OPERATOR 3 ~~=,
  OPERATOR 4 ~>=,
  OPERATOR 5 ~>>,
  FUNCTION 1 cf_compare( text, text );
