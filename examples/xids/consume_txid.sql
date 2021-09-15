/**
  * !!! DO NO TRY THIS IN PRODUCTION !!!
  *
  * The only purpose of this bunch of stuff is to
  * try a xid wraparound.
  *
  * The idea is as follows:
  * - use a table and insert slowly tuples without committing;
  * - use a procedure to consume all the xids in sequence
  *
  * Autovacuum should be turned off, so to leave only emergency freeze. However
  * since the transaction is never committing tuples, it can be left on.
  *
  *
  * To launch it:
  * 1) create table and rotuines using this script
  * 2) in a session launch the inserting function
  psql -h miguel -U luca -c "SELECT f_insert_records_forever();" testdb
  * 3) in another session launch the consuming xid procedure:
  psql -h miguel -U luca -c "call p_consume_xid();" testdb
  * 4) have a nice day waiting...
  */

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

  INFO:  Starting to consume transaction ids, reporting every 50000000 consumed xids
  INFO:  Consuming 26906 xid/sec: current xid is 3800000000 (real 16684901888), 49999999 transactions consumed so far (1858 secs elapsed)
  INFO:   |-> 3909582979 transactions to wraparound (estimated 145305 secs, at 2021-03-24 08:30:36.727671)
  INFO:   |-> read only at 2021-03-24 08:29:59.727671+01
  INFO:   |-> this report appears every 50000000 transactions, 1858 secs, next at 2021-03-22 16:39:49.727671


 */

/*
  Parameters:
  - lim the limit of xids to consume, NULL to consume all (i.e., execute an infinite loop)
  - report_every number of transactions after which report a progress
  - report_details report also statistics about timing, and this can require a few milliseconds



  If you inspect the WAL traffic with, for example, pg_waldump, you are going to see a lot of 'ABORT' records
like the following one

  rmgr: Transaction len (rec/tot):     34/    34, tx:    6455124, lsn: 17/7401BE60, prev 17/7401BE38, desc: ABORT 2021-07-14 06:55:03.923054 EDT
  rmgr: Transaction len (rec/tot):     34/    34, tx:    6455125, lsn: 17/7401BE88, prev 17/7401BE60, desc: ABORT 2021-07-14 06:55:03.923074 EDT
  rmgr: Transaction len (rec/tot):     34/    34, tx:    6455126, lsn: 17/7401BEB0, prev 17/7401BE88, desc: ABORT 2021-07-14 06:55:03.923093 EDT
  rmgr: Transaction len (rec/tot):     34/    34, tx:    6455127, lsn: 17/7401BED8, prev 17/7401BEB0, desc: ABORT 2021-07-14 06:55:03.923113 EDT
  rmgr: Transaction len (rec/tot):     34/    34, tx:    6455128, lsn: 17/7401BF00, prev 17/7401BED8, desc: ABORT 2021-07-14 06:55:03.923132 EDT


  To see the WAL traffic use pg_waldump in a way similar to the following:

  % sudo -u postgres /usr/pgsql-13/bin/pg_waldump -p $PGDATA/pg_wal  -s 17/728BA6A8 -f -t 7

  where you can get the wal starting point (-s) with pg_current_wal_lsn() or by the procedure output
  and have to use the follow (-f) flag as well as the timeline (-t) if different from 1.




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
  xid_age         bigint  := 0;
  epoch           int     := 0;
  
  wraparound_counter int  := 0;
  previous_epoch     int  := 0;
  autovacuum_enabled boolean := false;
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


  wraparound_counter := 0;

  -- select the current epoch
  -- this is going to be recomputed every
  -- transaction
  select txid_current() >> 32, current_setting( 'autovacuum' )::boolean
    into epoch, autovacuum_enabled;

  -- print some startup messages
  raise info 'Starting to consume transaction ids, reporting every % consumed xids', report_every;
  raise info 'Current WAL location (LSN) is %, current xid is %, current epoch is %',
    pg_current_wal_lsn(),     txid_current(), epoch;

  while true loop

      counter := counter + 1;
      exit when lim = counter;

        

    -- consume the xid
      select txid_current(),  mod( txid_current(), max_xid ), age( datfrozenxid ), txid_current() >> 32, current_setting( 'autovacuum' )::boolean
      into xid_abs, xid, xid_age, epoch, autovacuum_enabled
      from pg_database
      where datname = current_database();

      -- if the previous epoch is null, assign it
      IF previous_epoch IS NULL OR previous_epoch = 0 THEN
      	 previous_epoch := epoch;
     END IF;


    if previous_epoch <> epoch then
      -- there has been a wraparound
 	    wraparound_counter := wraparound_counter + 1;		
	    raise info 'WRAPAROUND % happened @ %: epoch is now %, previous epoch was %, xid is now % (real %)',
         wraparound_counter,
        clock_timestamp(),
        epoch,
        previous_epoch,
        xid,
        xid_abs;
	    previous_epoch      := epoch;

     end if;

     -- print something
     if counter % report_every = 0 then
        ts_end          := clock_timestamp();
        secs            := extract( epoch from ( ts_end - ts_start ) );
        total_secs      := total_secs + secs;
        ts_start        := clock_timestamp();
        raise info 'Consuming % xid/sec: current xid is % (real %, epoch %), % transactions consumed so far (% secs elapsed)'
                    , ( counter / total_secs )::int,
                      xid,
                      xid_abs,
                      epoch,
                      counter, total_secs::bigint;



       if autovacuum_enabled then
         raise info ' |->  autovacuum is active';
       else
         raise info ' |-> autovacuum is turned OFF! Emergency (anti-wraparound) autovacuum will work, however.';
       end if;

      if report_details then
          estimated_secs  := abs( max_xid - xid_age ) /  ( counter / total_secs )::bigint;

        raise info ' |-> % transactions to wraparound (estimated % secs, at %), database % was frozen % transactions ago',
                      abs( max_xid - xid_age ),
                      estimated_secs,
                      clock_timestamp()::timestamp
          + ( estimated_secs || ' seconds' )::interval,
          current_database(),
          xid_age;

       raise info ' |-> read only at % ',
                        clock_timestamp()
                         + (  ( max_xid - xid_age - xid_shutdown ) / ( counter / total_secs )::bigint || ' seconds' )::interval;

        raise info ' |-> autovacuum should freeze within % trasanctions, at %',
          ( current_setting( 'autovacuum_freeze_max_age' )::int - xid_age )
          , clock_timestamp()
          + (  ( current_setting( 'autovacuum_freeze_max_age' )::int - xid_age ) / ( counter / total_secs )::bigint || ' seconds' )::interval;
          
        raise info ' |-> current LSN is now at %', pg_current_wal_lsn();
        


        raise info ' |-> this report appears every % transactions, % secs, next at %',
         report_every,
         secs::bigint,
         clock_timestamp()::timestamp + ( secs::bigint || ' seconds' )::interval;

          -- are we in the warning threshold?
          if abs( max_xid - xid_age ) <= xid_warning then
             raise info ' |--> you are now within the % transactions warning', xid_warning;
             raise info ' |---> % transactions before system goes read-only!', max_xid - xid_age - xid_shutdown ;
         end if;
      end if;
     end if;

     -- nothing to do
     rollback;
  end loop;
end
$$ language plpgsql;



