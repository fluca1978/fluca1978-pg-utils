/*
 * Invoke this script with:

 % pgbench -s 300000 -f benchmark_regexp_replace.sql -U luca testdb

 * or a similar command.
 * It is required to have the table benchmark_replace to store the results.
 * Once run, it is possible to get some information as:

 testdb=> SELECT replacement_type, avg( ms ), min( ms ), max( ms ) FROM benchmark_replace GROUP BY replacement_type;
   replacement_type |          avg           | min |   max
  ------------------+------------------------+-----+----------
   regexp_replace   | 2.0050125666710534e-05 |   0 | 0.077236
   replace          |  4.934836999960355e-06 |   0 | 0.005685
  (2 rows)
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
    SELECT regexp_replace(
              regexp_replace(
                regexp_replace( x ,
                   		'<', '&lt;', 'g' )
          		, '>', '&gt;', 'g' )
        		, '&', '&amp;', 'g' )
    INTO y;

    ts_end := clock_timestamp();

    INSERT INTO benchmark_replace( text_to_translate, text_translated, ms, replacement_type )
    SELECT x, y,  extract( epoch from ( ts_end - ts_begin ) ), 'regexp_replace';

    RAISE DEBUG 'replace x 3 over [%] took % ms', x,  ( ts_end - ts_begin );

end loop;

end
$code$
language plpgsql;
