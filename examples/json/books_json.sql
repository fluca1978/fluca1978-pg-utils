CREATE TABLE IF NOT EXISTS jbooks (
       pk int generated always as identity
       , content jsonb NOT NULL
       , PRIMARY KEY( pk )
);


TRUNCATE TABLE jbooks;

INSERT INTO jbooks( content )
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


-- select all the title
SELECT content->'title' from jbooks;
/*
                ?column?
-----------------------------------------
 "Learn PostgreSQL"
 "PostgreSQL 11 Server Side Programming"
 "Learn PostgreSQL"
(3 rows)
*/


-- select the first author
SELECT (content->'authors')[ 0 ] from jbooks;

/*
    ?column?
----------------
 "Luca Ferrari"
 "Luca Ferrari"
 "Luca Ferrari"
(3 rows)
*/


/*
 Operators:
 -> extracts the key (either numeric or text)
 ->> extracts the value as text


estdb=> select pg_typeof( content -> 'title' ) from jbooks;
 pg_typeof
-----------
 jsonb
 jsonb
 jsonb
(3 rows)

testdb=> select pg_typeof( content ->> 'title' ) from jbooks;
 pg_typeof
-----------
 text
 text
 text
(3 rows)

*/
