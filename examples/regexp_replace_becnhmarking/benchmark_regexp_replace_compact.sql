/*
 * Invoke this script with:

 % pgbench -s 300000 -f benchmark_regexp_replace_compact.sql -U luca testdb

 * or a similar command.
 * It is required to have the table benchmark_replace to store the results.
 * Once run, it is possible to get some information as:

  testdb=> SELECT replacement_type, avg( ms ), min( ms ), max( ms ) FROM benchmark_replace GROUP BY replacement_type;
      replacement_type    |          avg           | min |   max
  ------------------------+------------------------+-----+----------
   regexp_replace         | 2.0656612333436503e-05 |   0 | 0.039055
   regexp_replace_compact | 0.00018001079899881362 |   0 |  0.06716
   replace                |  4.885953333294914e-06 |   0 | 0.027875
  (3 rows)

*/
    do
$code$
declare
   i int;
   x text;
   y text;
   ts_begin timestamp;
   ts_end   timestamp;
begin

for i in  1 .. :scale  loop
    ts_begin := clock_timestamp();
    x :=  '<?xml?> <formula> 10 < 20 && 30 > 20 </formula>'   || ' <i>' || i || '</i>';
    SELECT regexp_replace( x , '<(.*)>(.*)</\1>', '&lt;\1&gt;\2&lt;/\1&gt;', 'g' )
    INTO   y;

    SELECT regexp_replace( y , '<?xml(.*)?>', '&lt;?\1 ?&gt;', 'g' )
    INTO   y;


    ts_end := clock_timestamp();

    INSERT INTO benchmark_replace( text_to_translate, text_translated, ms, replacement_type )
    SELECT x, y,  extract( epoch from ( ts_end - ts_begin ) ), 'regexp_replace_compact';

    RAISE DEBUG 'replace x 3 over [%] took % ms', x,  ( ts_end - ts_begin );

end loop;

end
$code$
language plpgsql;
