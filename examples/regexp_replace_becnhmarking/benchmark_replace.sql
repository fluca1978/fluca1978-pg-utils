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
    SELECT replace(
              replace(
                replace( x ,
                   		'<', '&lt;' )
          		, '>', '&gt;' )
        		, '&', '&amp;' )
    INTO y;

    ts_end := clock_timestamp();

    INSERT INTO benchmark_replace( text_to_translate, text_translated, ms, replacement_type )
    SELECT x, y,  extract( epoch from ( ts_end - ts_begin ) ), 'replace';

    RAISE DEBUG 'replace x 3 over [%] took % ms', x,  ( ts_end - ts_begin );

end loop;

end
$code$
language plpgsql;
