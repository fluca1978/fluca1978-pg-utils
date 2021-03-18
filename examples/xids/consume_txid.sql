

CREATE TABLE IF NOT EXISTS wa (
    pk serial primary key
    , t text
    );

/**
  * Inserts record forever in the table, suspending for 20 minutes
  * between inserts
  */
  CREATE OR REPLACE FUNCTION
  f_insert_records_forever()
  RETURNS VOID
  AS
  $$
  declare
    counter bigint := 0;
  BEGIN
       WHILE true LOOP
          counter := counter + 1;
          RAISE INFO 'Inserting record % into wa %', counter, clock_timestamp();
  	INSERT INTO wa( t )
  	SELECT 'I am ' || txid_current() || ' from f_insert_records_wraparound @ ' || clock_timestamp();
  	PERFORM pg_sleep_for( '20 minutes' );
      END LOOP;
  END
  $$ LANGUAGE plpgsql;



    /*
 * Consumes a lot of xids without doing anything.
 *
 * !!!!! DO NOT TRY THIS IN PRODUCTION !!!!!!
 * This is going to consume all available transaction ids and, most notably,
 * will generate a great amount of subtransactions, consuming a lot of disk space.
 * THIS IS GOING TO SHUTDOWN YOUR POSTGRESQL!
 *
 * Example of invocation:

  testdb=> call p_consume_xid();

INFO:  Starting to consume transaction ids, reporting every 10000000 consumed xids

 */

/*
  Parameters:
  - lim the limit of xids to consume, NULL to consume all (i.e., execute an infinite loop)
  - report_every number of transactions after which report a progress
  - report_details report also statistics about timing, and this can require a few milliseconds
  */
create or replace procedure
p_consume_xid( lim bigint default null,
               report_every bigint default 50000000,
               report_details boolean default true  )
as
$$
declare
  xid     bigint;
  counter bigint := 0;
  max_xid bigint := 0;
  ts_start   timestamp;
  ts_end     timestamp;
  secs            numeric := 0;
  estimated_secs  numeric := 0;
  total_secs      numeric := 0;
  xid_warning     bigint  := 0;
  xid_shutdown    bigint  := 1000000;
  xid_abs         bigint  := 0;
  xid_age         bigint := 0;
begin
  -- compute the max value
  max_xid := pow( 2, 32 );

  -- when warnings will appear?
  xid_warning := xid_shutdown * 11;

  -- initialize the timestamp
  ts_start   := clock_timestamp();


  if lim is null then
     lim := max_xid;
  end if;

  if report_every is null or report_every > lim then
     report_every := lim;
  end if;

  raise info 'Starting to consume transaction ids, reporting every % consumed xids', report_every;

  while true loop

      counter := counter + 1;
      exit when lim = counter;



    -- consume the xid
      select txid_current(),  mod( txid_current(), max_xid ), age( datfrozenxid )
      into xid_abs, xid, xid_age
      from pg_database
      where datname = current_database();

     -- print something
     if xid % report_every = 0 then
        ts_end          := clock_timestamp();
        secs            := extract( epoch from ( ts_end - ts_start ) );
        total_secs      := total_secs + secs;
        ts_start        := clock_timestamp();
        raise info 'Consuming % xid/sec: current xid is % (real %), % transactions consumed so far (% secs elapsed)'
                    ,   ( counter / total_secs )::int, xid, xid_abs, counter, total_secs::int;

      if report_details then
          estimated_secs  := abs( max_xid - xid_age ) /  ( counter / total_secs )::bigint;

        raise info ' |-> % transactions to wraparound (estimated % secs, at %, read only at %) (this report appears every % transactions, % secs)',
                      abs( max_xid - xid_age ),
                      estimated_secs,
                      current_timestamp
                       + ( estimated_secs || ' seconds' )::interval,
                        current_timestamp
                         + ( estimated_secs || ' seconds' )::interval,
                      report_every,
                      secs::bigint;

          -- are we in the warning threshold?
          if abs( max_xid - xid_age ) <= xid_warning then
             raise info ' |--> you are now within the % transactions warning', xid_warning;
             raise info ' |---> % transactions before system goes read-only!', abs( max_xid - xid_age - xid_shutdown );
         end if;
      end if;
     end if;

     -- nothing to do
     rollback;
  end loop;
end
$$ language plpgsql;
