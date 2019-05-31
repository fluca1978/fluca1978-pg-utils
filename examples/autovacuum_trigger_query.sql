/*
 * A query to see how many tuples has to be changed on a table to trigger an
 * autovacuum (either vacuum or analyze).
 * The result is something like:
  relname  |  reltuples  | vacuum_trigger | analyze_trigger | v_base | v_scale | a_base | a_scale
----------+-------------+----------------+-----------------+--------+---------+--------+---------
 tm03 |  1.5237e+07 |        3047450 |         1523750 |     50 |     0.2 |     50 |     0.1
 tm10 | 1.48956e+07 |        2979170 |         1489610 |     50 |     0.2 |     50 |     0.1
 tm04 | 1.48854e+07 |        2977127 |         1488588 |     50 |     0.2 |     50 |     0.1
 tm12 | 1.48382e+07 |        2967698 |         1483874 |     50 |     0.2 |     50 |     0.1
 tm05 | 1.46707e+07 |        2934195 |         1467123 |     50 |     0.2 |     50 |     0.1
 tm01 | 1.43847e+07 |        2876991 |         1438520 |     50 |     0.2 |     50 |     0.1
 tm11 | 1.40957e+07 |        2819196 |         1409623 |     50 |     0.2 |     50 |     0.1
 tm02 | 1.35441e+07 |        2708871 |         1354460 |     50 |     0.2 |     50 |     0.1
 tm09 | 9.70561e+06 |        1941172 |          970611 |     50 |     0.2 |     50 |     0.1
 tm08 |           0 |             50 |              50 |     50 |     0.2 |     50 |     0.1
*/

WITH
v_scale AS
( SELECT setting::numeric AS v_scale FROM pg_settings WHERE name = 'autovacuum_vacuum_scale_factor' )
, v_threshold AS
( SELECT setting::integer AS v_base FROM pg_settings WHERE name = 'autovacuum_vacuum_threshold' )
, a_scale AS
( SELECT setting::numeric AS a_scale FROM pg_settings WHERE name = 'autovacuum_analyze_scale_factor' )
, a_threshold AS
( SELECT setting::integer AS a_base FROM pg_settings WHERE name = 'autovacuum_analyze_threshold' )
SELECT relname, reltuples,
( v_base + v_scale * reltuples )::integer AS vacuum_trigger,
( a_base + a_scale * reltuples )::integer AS analyze_trigger,
v_base, v_scale,
a_base, a_scale
FROM   pg_class, v_scale, v_threshold, a_scale, a_threshold
ORDER BY reltuples DESC;
