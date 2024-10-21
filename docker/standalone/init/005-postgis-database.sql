CREATE DATABASE postgis WITH owner luca;

\c postgis



CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE shapes(
   pk int generated always as identity,
   description text,
   geom geometry,
   primary key( pk )
);


INSERT INTO shapes( description, geom )
 VALUES( 'Triangolo A', 'POLYGON( ( 1 1, 1 5, 5 2, 1 1 ) )' )
, ( 'Triangolo B', 'POLYGON( ( 1 -1, 1 -5, 5 -2, 1 -1 ) )' )
, ( 'Rettangolo A', 'POLYGON( ( 1 1, 1 10, 10 10 , 10 1, 1 1 ) )' )
, ( 'Rettangolo B', 'POLYGON( ( 1 -1, 1 -10, 10 -10 , 10 -1, 1 -1 ) )' );


GRANT ALL ON TABLE shapes TO luca;
