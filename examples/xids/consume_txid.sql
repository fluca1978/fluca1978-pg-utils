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
INFO:  Consuming 43341 xid/sec: current xid is 1110000000, 9999999 transactions consumed so far (231 secs elapsed)
INFO:   |-> 1037483647 transactions to wraparound (estimated 23937 secs, at 2021-03-15 22:27:59.790675+01 ) (this report appears every 10000000 transactions, 231 secs)
INFO:  Consuming 47293 xid/sec: current xid is 1120000000, 19999999 transactions consumed so far (423 secs elapsed)
INFO:   |-> 1027483647 transactions to wraparound (estimated 21725 secs, at 2021-03-15 21:54:19.959369+01 ) (this report appears every 10000000 transactions, 192 secs)
INFO:  Consuming 49126 xid/sec: current xid is 1130000000, 29999999 transactions consumed so far (611 secs elapsed)
INFO:   |-> 1017483647 transactions to wraparound (estimated 20711 secs, at 2021-03-15 21:40:33.73678+01 ) (this report appears every 10000000 transactions, 188 secs)
INFO:  Consuming 50637 xid/sec: current xid is 1140000000, 39999999 transactions consumed so far (790 secs elapsed)
INFO:   |-> 1007483647 transactions to wraparound (estimated 19896 secs, at 2021-03-15 21:29:56.994531+01 ) (this report appears every 10000000 transactions, 179 secs)
INFO:  Consuming 51433 xid/sec: current xid is 1150000000, 49999999 transactions consumed so far (972 secs elapsed)
INFO:   |-> 997483647 transactions to wraparound (estimated 19393 secs, at 2021-03-15 21:24:37.200114+01 ) (this report appears every 10000000 transactions, 182 secs)
INFO:  Consuming 51846 xid/sec: current xid is 1160000000, 59999999 transactions consumed so far (1157 secs elapsed)
INFO:   |-> 987483647 transactions to wraparound (estimated 19046 secs, at 2021-03-15 21:21:54.325776+01 ) (this report appears every 10000000 transactions, 185 secs)
INFO:  Consuming 51489 xid/sec: current xid is 1170000000, 69999999 transactions consumed so far (1360 secs elapsed)
INFO:   |-> 977483647 transactions to wraparound (estimated 18984 secs, at 2021-03-15 21:24:14.575018+01 ) (this report appears every 10000000 transactions, 202 secs)
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
  ts_start   timestamp;
  ts_end     timestamp;
  secs            numeric := 0;
  estimated_secs  numeric := 0;
  total_secs      numeric := 0;
begin
  -- compute the max value
  max_xid := pow( 2, 31 ) - 1;

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
      select txid_current()
        into xid;

     -- print something
     if xid % report_every = 0 then
        ts_end          := clock_timestamp();
        secs            := extract( epoch from ( ts_end - ts_start ) );
        total_secs      := total_secs + secs;
        ts_start        := clock_timestamp();
        raise info 'Consuming % xid/sec: current xid is %, % transactions consumed so far (% secs elapsed)'
                    ,   ( counter / total_secs )::int, xid, counter, total_secs::int;

      if report_details then
          estimated_secs  := ( max_xid - xid ) /  ( counter / total_secs )::bigint;

        raise info ' |-> % transactions to wraparound (estimated % secs, at % ) (this report appears every % transactions, % secs)',
                      ( max_xid - xid ),
                      estimated_secs,
                      current_timestamp
                       + ( ( ( max_xid - xid ) / ( counter / total_secs ) )::bigint || ' seconds' )::interval,
                      report_every,
                      secs::bigint;
      end if;
     end if;

     -- nothing to do
     rollback;
  end loop;
end
$$ language plpgsql;
