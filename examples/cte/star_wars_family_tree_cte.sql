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
 pk |      name      | gender | parent_of |     status     | level
 ---+----------------+--------+-----------+----------------+-------
 1 | Kilo Ren       | t      |           | -- son --      |     0
 2 | Luke Skywalker | t      |           | -- son --      |     0
 3 | Rey            | f      |           | -- daughter -- |     0
 4 | Han Solo       | t      | {1,3}     | Kilo Ren       |     1
 5 | Leia Organa    | f      | {1,3}     | Kilo Ren       |     1
 6 | Darth Vader    | t      | {2,5}     | Luke Skywalker |     1
 7 | Padem Andala   | f      | {2,5}     | Luke Skywalker |     1
 4 | Han Solo       | t      | {1,3}     | Rey            |     1
 5 | Leia Organa    | f      | {1,3}     | Rey            |     1
 6 | Darth Vader    | t      | {2,5}     | Leia Organa    |     2
 7 | Padem Andala   | f      | {2,5}     | Leia Organa    |     2

and the main query compress it using array-join so that it outputs

     name      |                status
---------------+---------------------------------------
Darth Vader    | Father of Luke Skywalker, Leia Organa
Han Solo       | Father of Kilo Ren, Rey
Kilo Ren       | Father of none!
Leia Organa    | Mother of Kilo Ren, Rey
Luke Skywalker | Father of none!
Padem Andala   | Mother of Luke Skywalker, Leia Organa
Rey            | Mother of none!


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
          CASE  WHEN sw.level > 1 THEN ', '
                        ELSE ''
          END
         || sw.name
         , sw.level + 1 AS level
  FROM star_wars_family_tree f JOIN star_wars sw
  ON sw.pk = ANY( f.parent_of )
)


SELECT f.name
       , CASE f.gender WHEN true THEN 'Father of '
                                 ELSE 'Mother of '
         END
         ||
         CASE WHEN f.level = 0 THEN 'none!'
                               ELSE
                                     array_to_string(
                                               ARRAY( SELECT status FROM star_wars sw WHERE sw.pk = f.pk )
                                              , ', '
                                      )
        END AS status
       FROM star_wars f
       GROUP BY 1,2;
