/*
 * Consumes a lot of xids without doing anything.
 *
 * DO NOT TRY THIS IN PRODUCTION!!!!!!
 * This is going to consume all available transaction ids and, most notably,
 * will generate a great amount of subtransactions, consuming a lot of disk space.
 *
 * Example of invocation:

  testdb=> call p_consume_xid();

INFO:  Starting to consume transaction ids, reporting every 10000000 consumed xids
INFO:  Current xid is 400000000, 6253842 transactions consumed so far (127.07853 secs elapsed), 49212.420068126378 xid/sec
INFO:    1747483647 transactions to wraparound (estimated 85997899298345.471484340566 secs = 1433298321639.091191405676 mins = 23888305360.651519856761 hours = 995346056.693813327365 days) (this report appears every 10000000 transactions, 127.07853 secs)
INFO:  Current xid is 410000000, 16253842 transactions consumed so far (337.159563 secs elapsed), 48208.159529498500 xid/sec
INFO:    1737483647 transactions to wraparound (estimated 83760888834470.857861029500 secs = 1396014813907.847631017158 mins = 23266913565.130793850286 hours = 969454731.880449743762 days) (this report appears every 10000000 transactions, 210.081033 secs)
INFO:  Current xid is 420000000, 26253842 transactions consumed so far (545.892782 secs elapsed), 48093.403806903605 xid/sec
INFO:    1727483647 transactions to wraparound (estimated 83080568604993.523342847435 secs = 1384676143416.558722380791 mins = 23077935723.609312039680 hours = 961580655.150388001653 days) (this report appears every 10000000 transactions, 208.733219 secs)
INFO:  Current xid is 430000000, 36253842 transactions consumed so far (743.361865 secs elapsed), 48770.112790222296 xid/sec
INFO:    1717483647 transactions to wraparound (estimated 83761871179552.334874793512 secs = 1396031186325.872247913225 mins = 23267186438.764537465220 hours = 969466101.615189061051 days) (this report appears every 10000000 transactions, 197.469083 secs)
INFO:  Current xid is 440000000, 46253842 transactions consumed so far (941.869438 secs elapsed), 49108.549586466145 xid/sec
INFO:    1707483647 transactions to wraparound (estimated 83852045346779.555106630815 secs = 1397534089112.992585110514 mins = 23292234818.549876418509 hours = 970509784.106244850771 days) (this report appears every 10000000 transactions, 198.507573 secs)
INFO:  Current xid is 450000000, 56253842 transactions consumed so far (1145.516837 secs elapsed), 49107.826426474428 xid/sec
INFO:    1697483647 transactions to wraparound (estimated 83359732298654.789393678916 secs = 1389328871644.246489894649 mins = 23155481194.070774831577 hours = 964811716.419615617982 days) (this report appears every 10000000 transactions, 203.647399 secs)
 ...
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
        ts_start        := clock_timestamp();
        raise info 'Current xid is %, % transactions consumed so far (% secs elapsed), % xid/sec'
                    , xid, counter, total_secs, ( counter / total_secs );

      if report_details then
           estimated_secs  := ( counter / total_secs ) * ( max_xid - xid );
          estimated_mins  := estimated_secs / 60;
          estimated_hours := estimated_secs / 3600;
          estimated_days  := estimated_secs / ( 3600 * 24 );

        raise info '  % transactions to wraparound (estimated % secs = % mins = % hours = % days) (this report appears every % transactions, % secs)',
                      ( max_xid - xid ),
                      estimated_secs,
                      estimated_mins,
                      estimated_hours,
                      estimated_days,
                      report_every,
                      secs;
      end if;
     end if;

     -- nothing to do
     rollback;
  end loop;
end
$$ language plpgsql;
