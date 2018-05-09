BEGIN;

CREATE TABLE star_wars_family_tree (
       pk serial PRIMARY KEY,
       name      text NOT NULL,
       gender    bool DEFAULT true, -- true = male
       parent_of int[]
);

INSERT INTO star_wars_family_tree( name, parent_of, gender )
VALUES
( 'Kilo Ren', NULL, true )
, ( 'Luke Skywalker', NULL, true )
, ( 'Rey', NULL, false )
, ( 'Han Solo', ARRAY[1,3], true )
, ( 'Leia Organa', ARRAY[1,3], false )
, ( 'Darth Vader', ARRAY[2,5], true )
, ( 'Padem Andala', ARRAY[2,5], false );

COMMIT;

/*
 * The recursive CTE provides the following:
 pk |      name      | gender | parent_of |          stato           | level
----+----------------+--------+-----------+--------------------------+-------
  1 | Kilo Ren       | t      |           | -- son --                |     0
  2 | Luke Skywalker | t      |           | -- son --                |     0
  3 | Rey            | f      |           | -- daughter --           |     0
  4 | Han Solo       | t      | {1,3}     | Father of Kilo Ren       |     1
  5 | Leia Organa    | f      | {1,3}     | Mother of Kilo Ren       |     1
  6 | Darth Vader    | t      | {2,5}     | Father of Luke Skywalker |     1
  7 | Padem Andala   | f      | {2,5}     | Mother of Luke Skywalker |     1
  4 | Han Solo       | t      | {1,3}     | Father of Rey            |     1
  5 | Leia Organa    | f      | {1,3}     | Mother of Rey            |     1
  6 | Darth Vader    | t      | {2,5}     | Father of Leia Organa    |     2
  7 | Padem Andala   | f      | {2,5}     | Mother of Leia Organa    |     2

and the main query compress it using array-join so that it outputs

     name      |                 array_to_string
---------------+-------------------------------------------------
Kilo Ren       | -- son --
Luke Skywalker | -- son --
Rey            | -- daughter --
Han Solo       | Father of Kilo Ren, Father of Rey
Leia Organa    | Mother of Kilo Ren, Mother of Rey
Darth Vader    | Father of Luke Skywalker, Father of Leia Organa
Padem Andala   | Mother of Luke Skywalker, Mother of Leia Organa

*/

WITH RECURSIVE star_wars AS
(
  -- termine non ricorsivo
  SELECT *,
         CASE gender WHEN true THEN '-- son --'
                     ELSE '-- daughter --'
         END
         AS status
         , 0 AS level
  FROM star_wars_family_tree
  WHERE parent_of IS NULL


  UNION

  SELECT f.*,
          CASE f.gender WHEN true THEN 'Father of '
                        ELSE 'Mother of '
          END
         || sw.name
         , sw.level + 1 AS level
  FROM star_wars_family_tree f JOIN star_wars sw
  ON sw.pk = ANY( f.parent_of )
)

SELECT f.name
       , array_to_string(
          ARRAY( SELECT status FROM star_wars sw WHERE sw.pk = f.pk )
          , ', '
       ) AS status
       FROM star_wars_family_tree f;
