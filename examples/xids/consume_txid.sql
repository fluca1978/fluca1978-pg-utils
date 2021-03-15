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
  INFO:  Current xid is 770000000, 91413546 transactions consumed so far (1847 secs elapsed), 49496 xid/sec
  INFO:   |-> 1377483647 transactions to wraparound (estimated 27830 secs = 464 mins = 8 hours = 0 days) (this report appears every 10000000 transactions, 199 secs)
  INFO:  Current xid is 780000000, 101413546 transactions consumed so far (2048 secs elapsed), 49529 xid/sec
  INFO:   |-> 1367483647 transactions to wraparound (estimated 27609 secs = 460 mins = 8 hours = 0 days) (this report appears every 10000000 transactions, 201 secs)
  INFO:  Current xid is 790000000, 111413546 transactions consumed so far (2250 secs elapsed), 49522 xid/sec
  INFO:   |-> 1357483647 transactions to wraparound (estimated 27411 secs = 457 mins = 8 hours = 0 days) (this report appears every 10000000 transactions, 202 secs)
 ...
 */

/*
  Parameters:
  - lim the limit of xids to consume, NULL to consume all (i.e., execute an infinite loop)
  - report_every number of transactions after which report a progress
  - report_details report also statistics about timing, and this can require a few milliseconds
  */
create or replace procedure
p_consume_xid( lim bigint default null,
               report_every bigint default 10000000,
               report_details boolean default true  )
as
$$
declare
  xid     bigint;
  counter bigint := 0;
  max_xid bigint := 0;
  ts_start timestamp;
  ts_end   timestamp;
  secs            numeric := 0;
  estimated_secs  numeric := 0;
  estimated_mins  numeric := 0;
  estimated_hours numeric := 0;
  estimated_days  numeric := 0;
  total_secs      numeric := 0;
begin
  -- compute the max value
  max_xid := pow( 2, 31 ) - 1;

  -- initialize the timestamp
  ts_start := clock_timestamp();

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
      select txid_current()
        into xid;

     -- print something
     if xid % report_every = 0 then
        ts_end          := clock_timestamp();
        secs            := extract( epoch from ( ts_end - ts_start ) );
        total_secs      := total_secs + secs;
        ts_start        := clock_timestamp();
        raise info 'Current xid is %, % transactions consumed so far (% secs elapsed), % xid/sec'
                    , xid, counter, total_secs::int, ( counter / total_secs )::int;

      if report_details then
          estimated_secs  := ( max_xid - xid ) /  ( counter / total_secs )::bigint;
          estimated_mins  := estimated_secs / 60;
          estimated_hours := estimated_secs / 3600;
          estimated_days  := estimated_secs / ( 3600 * 24 );

        raise info ' |-> % transactions to wraparound (estimated % secs = % mins = % hours = % days) (this report appears every % transactions, % secs)',
                      ( max_xid - xid ),
                      estimated_secs,
                      estimated_mins::bigint,
                      estimated_hours::bigint,
                      estimated_days::bigint,
                      report_every,
                      secs::bigint;
      end if;
     end if;

     -- nothing to do
     rollback;
  end loop;
end
$$ language plpgsql;
