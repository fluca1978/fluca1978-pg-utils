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
               report_every bigint default 1000000 )
as
$$
declare
  xid     bigint;
  counter bigint := 0;
  max_xid bigint := 0;
begin
  -- compute the max value
  max_xid := pow( 2, 31 ) - 1;


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
        raise info 'Current xid is %, % consumed so far, % to wraparound (report every %)',
                      xid,
                      counter,
                      ( max_xid - xid ),
                      report_every;
     end if;

     -- nothing to do
     rollback;
  end loop;
end
$$ language plpgsql;
