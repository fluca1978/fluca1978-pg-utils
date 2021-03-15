/*
 * Consumes a lot of xids without doing anything.
 *
 * Example of invocation:
  dbtest=> call p_consume_xid();
  INFO:  Current xid is 34000000, 146287 consumed totally (report every 1000000)
  INFO:  Current xid is 35000000, 1146287 consumed totally (report every 1000000)
  INFO:  Current xid is 36000000, 2146287 consumed totally (report every 1000000)
  INFO:  Current xid is 37000000, 3146287 consumed totally (report every 1000000)
  ...
  INFO:  Current xid is 120000000, 8674967 consumed totally (report every 1000000)
  INFO:  Current xid is 121000000, 9674967 consumed totally (report every 1000000)
  WARNING:  terminating connection because of crash of another server process
  DETAIL:  The postmaster has commanded this server process to roll back the current transaction and exit, because another server process exited abnormally and possibly corrupted shared memory.
  HINT:  In a moment you should be able to reconnect to the database and repeat your command.
  server closed the connection unexpectedly
  This probably means the server terminated abnormally
  before or while processing the request.
  The connection to the server was lost. Attempting reset: Failed.

*/


create or replace procedure
p_consume_xid( lim bigint default null,
               report_every bigint default 10000000 )
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

  raise info 'Starting to consume transaction ids, reporting every % consumed xids', report_every;

  while true loop

      counter := counter + 1;
      if lim is not null  then
         exit when lim = counter;
      end if;


    -- consume the xid
      select txid_current()
        into xid;

     -- print something
     if xid % report_every = 0 then
        ts_end          := clock_timestamp();
        secs            := extract( epoch from ( ts_end - ts_start ) );
        total_secs      := total_secs + secs;
        estimated_secs  := ( counter / total_secs ) * ( max_xid - xid );
        estimated_mins  := estimated_secs / 60;
        estimated_hours := estimated_secs / 3600;
        estimated_days  := estimated_secs / ( 3600 * 24 );
        ts_start        := clock_timestamp();
        raise info 'Current xid is %, % consumed so far (% secs elapsed), % transactions to wraparound (estimated % secs = % mins = % hours = % days) (this report appears every % transactions, % secs)',
                      xid,
                      counter,
                      total_secs,
                      ( max_xid - xid ),
                      estimated_secs,
                      estimated_mins,
                      estimated_hours,
                      estimated_days,
                      report_every,
                      secs;
     end if;

     -- nothing to do
     rollback;
  end loop;
end
$$ language plpgsql;
