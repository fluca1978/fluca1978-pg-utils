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







