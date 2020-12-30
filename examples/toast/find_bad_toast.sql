/**
 * find_bad_toast.sql
 * Utility functions to inspect TOAST data and get records that could have been damaged.
 *
 * Inspired by <http://www.databasesoup.com/2013/10/de-corrupting-toast-tables.html>
 */

/**
 * A function to get the list of possible toast-able columns.
 * The idea is to query the table system catalog to get
 * all the columns that can have a toastable state.
 *
 * Example of invocation:
 *  testdb=> select oid, relname from pg_class where relname = 'crashy_table';
 *  oid  |   relname    
 *  -------+--------------
 *  17022 | crashy_table
 *  (1 row)
 * 
 * testdb=> select f_enumerate_toastable_columns( 17022 );
 * f_enumerate_toastable_columns 
 * -------------------------------
 * boundary
 * t
 * (2 rows)
 *
 *
 */
 CREATE OR REPLACE FUNCTION f_enumerate_toastable_columns( tablez oid )
 RETURNS SETOF text
 AS $CODE$

DECLARE
BEGIN
-- the pg_attribute.attstorage stores a letter
-- to indicate the type of storage. Usually this is a clone
-- of what is set up in the pg_type catalog, but can be changed
-- depending on the value of the column field

RETURN QUERY
SELECT attname::text
FROM   pg_attribute
WHERE  attrelid = tablez
AND    attstorage IN ('x', 'e')  -- x = extended,  e = external
;
END

$CODE$
LANGUAGE plpgsql;


/**
 * Overloading of the function to accept a simple name
 * of table.
 * Example of invocation:

 */
CREATE OR REPLACE FUNCTION f_enumerate_toastable_columns( tablez text )
RETURNS SETOF text
AS $CODE$

DECLARE
BEGIN
  RETURN QUERY SELECT f_enumerate_toastable_columns( tablez::regclass );
END

$CODE$
LANGUAGE plpgsql;


/**
 * A function that tries to individuate tuples with wrong or corruptd toast data.
 * The idea is to try to execute a query that will de-toast the data
 * on every record, so to catch the wrong tuples.
 *
 * The function accepts the table to scan and the primary key, that is assumed
 * to be a bigint (serial, generated always and so on).
 * The function returns a table with a single record that will provide
 * the information about the health ratio of the table and an array with
 * all the wrong identifiers of the tuples.
 *
 * WARNING: this function scans every single record one at a time, so it can
 * be really slow on large tables. For this reason, is is possible to specify
 * an optional row limit and offset to invoke iteratively with table "chunks".
 *
 *
 * Example of invocation:

testdb=> SELECT * FROM f_find_bad_toast( 'crashy_table', 'id' );
NOTICE:  Record with id = 16385 of table crashy_table has corrupted toast data!
NOTICE:  Record with id = 16386 of table crashy_table has corrupted toast data!
NOTICE:  Record with id = 16387 of table crashy_table has corrupted toast data!
INFO:  3 record analyzed in table crashy_table, 0 healthy, 3 with corrupted toast data
-[ RECORD 1 ]----+------------------------------------------------------------------------------------------------------------------------
total            | 3
ok               | 0
ko               | 3
health_ratio     | 0
damage_ratio     | 100
description      | Table crashy_table has 100% toast data damaged (toast relation pg_toast.pg_toast_17022 on disk file [base/17021/33597])
damage_tuple_ids | {16385,16386,16387}


If you need more messages, you can enable the debug level:

testdb=> set client_min_messages to debug;
SET
testdb=> SELECT * FROM f_find_bad_toast( 'crashy_table', 'id' );
DEBUG:  Toast table pg_toast.pg_toast_17022 with OID 17209 (on disk [base/17021/33597])
DEBUG:  Prepared query [SELECT id FROM crashy_table ORDER BY 1]
DEBUG:  Preparing to de-toast record pk = 16385
DEBUG:  Prepared query [SELECT  lower( boundary::text )  ||  lower( t::text )  FROM crashy_table WHERE id = '16385']
DEBUG:  building index "pg_toast_33985_index" on table "pg_toast_33985" serially
NOTICE:  Record with id = 16385 of table crashy_table has corrupted toast data!
DEBUG:  Preparing to de-toast record pk = 16386
DEBUG:  Prepared query [SELECT  lower( boundary::text )  ||  lower( t::text )  FROM crashy_table WHERE id = '16386']
DEBUG:  building index "pg_toast_33991_index" on table "pg_toast_33991" serially
NOTICE:  Record with id = 16386 of table crashy_table has corrupted toast data!
DEBUG:  Preparing to de-toast record pk = 16387
DEBUG:  Prepared query [SELECT  lower( boundary::text )  ||  lower( t::text )  FROM crashy_table WHERE id = '16387']
DEBUG:  building index "pg_toast_33997_index" on table "pg_toast_33997" serially
NOTICE:  Record with id = 16387 of table crashy_table has corrupted toast data!
INFO:  3 record analyzed in table crashy_table, 0 healthy, 3 with corrupted toast data
-[ RECORD 1 ]----+------------------------------------------------------------------------------------------------------------------------
total            | 3
ok               | 0
ko               | 3
health_ratio     | 0
damage_ratio     | 100
description      | Table crashy_table has 100% toast data damaged (toast relation pg_toast.pg_toast_17022 on disk file [base/17021/33597])
damage_tuple_ids | {16385,16386,16387}

*/
CREATE OR REPLACE FUNCTION f_find_bad_toast( tablez text,
                                             pk text,
                                             tuple_limit bigint  DEFAULT 0,
                                             tuple_offset bigint DEFAULT 0 )
RETURNS TABLE( total bigint,
               ok bigint,
               ko bigint,
               health_ratio float,
               damage_ratio float,
               description text,
               damage_tuple_ids bigint[] )
AS $CODE$

DECLARE
  toast_oid      oid;
  toast_tablez   text;
  toast_filename text;

  query_pk text;
  query_detoast text;
  column_counter int := 0;

  current_column_to_detoast  text;
  current_pk bigint;

  current_detoasted_data text;

  ok_counter bigint := 0;
  ko_counter bigint := 0;
  total_counter bigint := 0;
  damage_ratio float := 0;

  wrong_tuple_ids bigint[];
BEGIN

  -- first of all, find out the toastable table
  SELECT reltoastrelid, reltoastrelid::regclass, pg_relation_filepath( reltoastrelid::regclass )
  INTO   toast_oid, toast_tablez, toast_filename
  FROM   pg_class
  WHERE  relname = tablez
  AND    relkind = 'r';

  -- check that the table has the potential data toasted!
  IF toast_oid IS NULL OR toast_oid = 0 THEN
     RAISE NOTICE 'The table % does not have any toast data associated!', tablez;
     RETURN;
  END IF;



  RAISE DEBUG 'Toast table % with OID % (on disk [%])',
                     toast_tablez,
                     toast_oid,
                     toast_filename;


  -- dynamically create a query to select all the records
  query_pk = format( 'SELECT %I FROM %I ORDER BY 1', pk, tablez );
  IF tuple_limit > 0 THEN
     query_pk = format( '%s LIMIT %s', query_pk, tuple_limit );
  END IF;
  IF tuple_offset > 0 THEN
     query_pk = format( '%s OFFSET %s', query_pk, tuple_offset );
  END IF;
  RAISE DEBUG 'Prepared query [%]', query_pk;

  FOR current_pk IN EXECUTE query_pk LOOP
      RAISE DEBUG 'Preparing to de-toast record pk = %', current_pk;
      total_counter = total_counter + 1;

      column_counter = 0;
      query_detoast = 'SELECT ';
      FOR current_column_to_detoast IN SELECT f_enumerate_toastable_columns( tablez ) LOOP

          IF column_counter > 0 THEN
             query_detoast = query_detoast || ' || ';
          END IF;
          query_detoast = query_detoast || format( ' lower( %I::text ) ', current_column_to_detoast );
          column_counter = column_counter + 1;
      END LOOP;

      query_detoast = query_detoast || format( ' FROM %I WHERE %I = %L', tablez, pk, current_pk );
      RAISE DEBUG 'Prepared query [%]', query_detoast;

      BEGIN
         EXECUTE query_detoast
         INTO    current_detoasted_data;

        PERFORM  length( current_detoasted_data );
        RAISE DEBUG 'Succesfully executed query [%]', query_detoast;
        ok_counter = ok_counter + 1;
      EXCEPTION
        WHEN OTHERS THEN
             ko_counter = ko_counter + 1;
             wrong_tuple_ids = array_append( wrong_tuple_ids, current_pk );
             RAISE NOTICE 'Record with % = % of table % has corrupted toast data!', pk, current_pk, tablez;

      END;

  END LOOP;

  RAISE INFO '% record analyzed in table %, % healthy, % with corrupted toast data',
                total_counter,
                tablez,
                ok_counter,
                ko_counter;


  -- compute the damage ratio, only
  -- if tuples have been effecively read
  IF total_counter > 0 THEN
     damage_ratio = ( total_counter - ok_counter ) / total_counter::float * 100;
  END IF;

  RETURN QUERY
  SELECT total_counter AS total,
         ok_counter    AS ok,
         ko_counter    AS ko,
         100 - damage_ratio AS health_ratio,
         damage_ratio       AS damage_ratio,
         format( 'Table %I has %s%% toast data damaged (toast relation %s on disk file [%s])',
                  tablez,
                  damage_ratio,
                  toast_tablez,
                  toast_filename ) AS description,
        wrong_tuple_ids AS damaged_tuple_ids;

END

$CODE$
LANGUAGE plpgsql;
