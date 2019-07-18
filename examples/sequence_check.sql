/*
 * A function that inspects sequences
 * and reports back how much remaining 'entries'
 * the sequence will produce.
 *
 * Example of invocation:

testdb=# select * from seq_check() ORDER BY remaining;
       seq_name        | current_value |    lim     | remaining  | cycle |
-----------------------|---------------|------------|------------|-------|
public.persona_pk_seq  |       5000000 | 2147483647 |     214248 | t     |
public.root_pk_seq     |         50000 | 2147483647 | 2147433647 | f     |
public.students_pk_seq |             7 | 2147483647 | 2147483640 | f     |
(3 rows)
*/

CREATE OR REPLACE FUNCTION seq_check()
RETURNS TABLE( seq_name text, current_value bigint, lim bigint, remaining bigint, cycle boolean )
AS $CODE$
DECLARE
  query text;
  schemaz name;
  seqz    name;
  seqid   oid;
BEGIN

  FOR schemaz, seqz, seqid IN   SELECT n.nspname, c.relname, c.oid
                         FROM   pg_class c
                         JOIN   pg_namespace n ON n.oid = c.relnamespace
                         WHERE  c.relkind = 'S' --sequence
                    LOOP

     RAISE DEBUG 'Inspecting %.%', schemaz, seqz;

     query := format( 'SELECT ''%s.%s'', last_value, s.seqmax AS lim, ( (s.seqmax - last_value) / s.seqincrement)::bigint AS remaining, s.seqcycle AS cycle  FROM %I.%I, pg_sequence s WHERE s.seqrelid = %s',
                      quote_ident( schemaz ),
                      quote_ident( seqz ),
                      schemaz,
                      seqz,
                      seqid );

     RAISE DEBUG 'Query [%]', query;
     RETURN QUERY EXECUTE query;
  END LOOP;


END
$CODE$
LANGUAGE plpgsql
STRICT;
