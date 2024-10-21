-- create a new database
CREATE DATABASE testdb WITH owner luca;

-- now connect to the forum database
-- and execute all the population statements
\c testdb


-- must be created by superuser, before changing
-- the current role!
CREATE EXTENSION IF NOT EXISTS plperl;
CREATE EXTENSION IF NOT EXISTS bool_plperl;
CREATE EXTENSION IF NOT EXISTS plpython3u;




CREATE OR REPLACE FUNCTION
check_codice_fiscale_python( cf text )
RETURNS bool
AS $CODE$
   import re
   if re.match( '^[A-Z]{3}[A-Z]{3}\\d{2}[A-Z]\\d{2}[A-Z]\\d{3}[A-Z]$', cf ):
      return True
   else:
     return False
$CODE$
LANGUAGE plpython3u;

--GRANT USAGE ON check_codice_fiscale_python TO luca;




SET ROLE TO luca;

CREATE SCHEMA luca AUTHORIZATION luca;


CREATE TABLE scores
  (
    pk int GENERATED ALWAYS AS IDENTITY
    , person text
    , team   text
    , class  text
    , score  int DEFAULT 0
    , PRIMARY KEY( pk )
  );

INSERT INTO scores( person, team, class, score )
VALUES
  ( 'Luca', 'Team-A', 'SM', 50 )  -- seniores maschile
  , ( 'Alberto', 'Team-A', 'SM', 30 )  -- seniores maschile
  , ( 'Filippo', 'Team-B', 'JM', 28 )
  , ( 'Andrea', 'Team-B', 'JM', 22 )

, ( 'Emanuela', 'Team-A', 'SF', 53 )
, ( 'Barbara', 'Team-B', 'SF', 39 )
, ( 'Simona', 'Team-A', 'JF', 29 )
, ( 'Giada', 'Team-B', 'JF', 28 )
;









CREATE OR REPLACE FUNCTION
check_codice_fiscale_perl( text )
RETURNS bool
TRANSFORM FOR TYPE bool
AS $CODE$
  $_[0] =~ /^ [A-Z]{6} \d{2} [A-Z] \d{2} [A-Z] \d{3} [A-Z] $/xi;
$CODE$
LANGUAGE plperl;








SET ROLE to postgres;

CREATE OR REPLACE FUNCTION
py_check_codice_fiscale( cf text )
RETURNS bool
AS $CODE$
   import re
   pattern = re.compile( r'[A-Z]{6}\d{2}[A-Z]\d{2}[A-Z]\d{3}[A-Z]$' )
   # `match` anchors at the beginning of the string!
   if pattern.match( cf ) is not None:
      return True
   else:
      return False
$CODE$
LANGUAGE plpython3u;


GRANT EXECUTE ON FUNCTION py_check_codice_fiscale TO luca;


CREATE OR REPLACE FUNCTION
py_select_highest_score( threshold int DEFAULT NULL )
RETURNS TABLE( who text, score int )
AS $CODE$
   query = "SELECT person || ' (' || team || ')' as who, score FROM luca.scores WHERE score <= $1;"

   global threshold                                            # note usage of global!
   if threshold is None or threshold < 0:
      threshold = 0

   prepared_statement = plpy.prepare( query, [ 'int' ] )       # note usage of list of parameter types
   tuples = plpy.execute( prepared_statement, [ threshold ] )  # note usage of list of parameter values

   highest = None
   for t in tuples:
       if highest is None or t[ 'score' ] > highest[ 'score' ]:
       	  highest = t

   # returns a table, so use a list
   return [ highest ]
$CODE$
LANGUAGE plpython3u;


GRANT EXECUTE ON FUNCTION py_select_highest_score TO luca;





CREATE TABLE IF NOT EXISTS luca.jbooks (
       pk int generated always as identity
       , content jsonb NOT NULL
       , PRIMARY KEY( pk )
);


TRUNCATE TABLE luca.jbooks;
GRANT ALL ON TABLE luca.jbooks TO luca;

INSERT INTO luca.jbooks( content )
VALUES ( '{ "title" : "Learn PostgreSQL",
             "authors" : [ "Luca Ferrari", "Enrico Pirozzi" ],
            "info" : {
	         "year" : 2020, "edition" : 1 } }' )
, ( '{ "title" : "PostgreSQL 11 Server Side Programming",
       "authors" : [ "Luca Ferrari" ],        "info" : { "year" : 2018 }
       }' )
, ( '{ "title" : "Learn PostgreSQL",
       "authors" : [ "Luca Ferrari", "Enrico Pirozzi" ],
       "info" : {
           "year" : 2020, "edition" : 2 } }' )
;
