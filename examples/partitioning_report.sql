/*
 * Paritioning status query.
 * Inspired by <https://www.postgresql.org/message-id/otalb9%245ma%241%40blaine.gmane.org>
 *
 * Example of output:

-[ RECORD 1 ]-----------+-------------------------------------------------
table_name              | images_root
is_root                 | t
reltuples               | 0
relpages                | 0
partitioning_type       | BY RANGE
table_parent_name       |
partitioning_values     |
sub_partitioning_values |
-[ RECORD 2 ]-----------+-------------------------------------------------
table_name              | images_2015
is_root                 | f
reltuples               | 5036
relpages                | 83
partitioning_type       | not partitioned
table_parent_name       | images_root
partitioning_values     | FOR VALUES FROM ('2015-01-01') TO ('2016-01-01')
sub_partitioning_values |

-[ RECORD 3 ]-----------+-------------------------------------------------
table_name              | images_2017
is_root                 | f
reltuples               | 0
relpages                | 0
partitioning_type       | BY LIST
table_parent_name       | images_root
partitioning_values     | FOR VALUES FROM ('2017-01-01') TO ('2018-01-01')
sub_partitioning_values | date_part('month'::text, modificationdate)

*/

WITH RECURSIVE inheritance_tree AS (
     SELECT   c.oid AS table_oid
            , c.relname  AS table_name
            , NULL::name AS table_parent_name
            , c.relispartition AS is_partition
            , true AS is_root
     FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relkind = 'p'
     AND   c.relispartition = false

     UNION ALL

     SELECT inh.inhrelid AS table_oid
          , c.relname AS table_name
          , cc.relname AS table_parent_name
          , c.relispartition AS is_partition
          , false AS is_root
     FROM inheritance_tree it
     JOIN pg_inherits inh ON inh.inhparent = it.table_oid
     JOIN pg_class c ON inh.inhrelid = c.oid
     JOIN pg_class cc ON it.table_oid = cc.oid

)
SELECT
          it.table_name
        , is_root
        , c.reltuples
        , c.relpages
        , CASE p.partstrat
               WHEN 'l' THEN 'BY LIST'
               WHEN 'r' THEN 'BY RANGE'
               WHEN 'h' THEN 'BY HASH'
               ELSE 'not partitioned'
          END AS partitioning_type
        , it.table_parent_name
        , pg_get_expr( c.relpartbound, c.oid, true ) AS partitioning_values
        , pg_get_expr( p.partexprs, c.oid, true )    AS sub_partitioning_values
FROM inheritance_tree it
JOIN pg_class c ON c.oid = it.table_oid
LEFT JOIN pg_partitioned_table p ON p.partrelid = it.table_oid
ORDER BY 2 DESC,1,3;
