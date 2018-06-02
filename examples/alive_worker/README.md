
# Introduction
---

This is a simple skeleton for a background worker registered at the PostgreSQL startup.

The idea behind this worker is to simulate logging every fixed time (10 seconds) to register that the server is alive. As you can imagine, this is simple useless for a database server.

However, this allows for a gentle introduction to the background worker usage.

This example is inspired by `src/test/modules/worker_spi` in the official PostgreSQL source tree.

The module has been developed and tested on PostgreSQL 9.6.5, FreeBSD 11-RELEASE.

# Running the worker
---

In the logs the module will print something like the following:

```
 INFO:   alive_worker::_PG_init registering worker [alive worker]
 DEBUG:  registering background worker "alive worker"
 DEBUG:  loaded library "alive_worker"
 DEBUG:  starting alive_worker::worker_main
 DEBUG:  alive_worker in main loop
 DEBUG:  alive_worker executing query [INSERT INTO public.log_table( message ) VALUES( 'STILL ALIVE and counting! 1' ) ] by [luca]
 DEBUG:  alive_worker query OK!
 DEBUG:  alive_worker in main loop
 DEBUG:  alive_worker executing query [INSERT INTO public.log_table( message ) VALUES( 'STILL ALIVE and counting! 2' ) ] by [luca]
 DEBUG:  alive_worker query OK!
 DEBUG:  alive_worker in main loop
```

and the `log_table` will be populated as follows:

```
 > SELECT * FROM log_table;
 pk |           message            |             ts
----|------------------------------|----------------------------
  4 | STILL ALIVE and counting! 1  | 2017-11-09 15:05:09.446884
  5 | STILL ALIVE and counting! 2  | 2017-11-09 15:05:19.44873
  6 | STILL ALIVE and counting! 3  | 2017-11-09 15:05:29.52069
  7 | STILL ALIVE and counting! 4  | 2017-11-09 15:05:39.527419
  8 | STILL ALIVE and counting! 5  | 2017-11-09 15:05:49.557702
  9 | STILL ALIVE and counting! 6  | 2017-11-09 15:05:59.624813
 10 | STILL ALIVE and counting! 7  | 2017-11-09 15:06:03.171599
 11 | STILL ALIVE and counting! 1  | 2017-11-09 15:07:39.313099
 12 | STILL ALIVE and counting! 2  | 2017-11-09 15:07:49.320683
 13 | STILL ALIVE and counting! 3  | 2017-11-09 15:07:59.375726
 14 | STILL ALIVE and counting! 4  | 2017-11-09 15:08:09.378152
 15 | STILL ALIVE and counting! 5  | 2017-11-09 15:08:19.400942
 16 | STILL ALIVE and counting! 6  | 2017-11-09 15:08:29.453949
 17 | STILL ALIVE and counting! 7  | 2017-11-09 15:08:39.555219
 18 | STILL ALIVE and counting! 8  | 2017-11-09 15:08:49.599897
 19 | STILL ALIVE and counting! 9  | 2017-11-09 15:08:59.70608
 20 | STILL ALIVE and counting! 10 | 2017-11-09 15:09:09.74592
 21 | STILL ALIVE and counting! 11 | 2017-11-09 15:09:19.827007
 22 | STILL ALIVE and counting! 12 | 2017-11-09 15:09:20.71118
```

## Stopping the worker process
---

In order to terminate the process send a `SIGTERM` to the process running.

First of all find out the process, that is named `alive_worker`:

```
 % ps -auxw | grep alive_worker
 postgres 3312   0.0  5.4 201368 26636  -  Ss   15:07     0:00.01 postgres: bgworker: alive worker    (postgres)
```

and then send a `TERM` signal:

```
 % sudo kill -TERM 3312
```


# Installation
---

In order to install this module do the following steps:

1. `make` to compile the module (you could need `gmake` on Unix);
2. run with root privileges `make install`;
3. edit `postgresql.conf` and ensure the two following lines are configured properly:
   a) ensure the `shared_preload_libraries` contains the `alive_worker` library name as for instance

   ```
   shared_preload_libraries = 'alive_worker'
   ```

   b) ensure you have at least one worker thread, therefore `max_worker_processes` is greater than one, as for instance

   ```
   max_worker_processes = 8
   ```

4. ensure you have a database named `testdb` and a user named `luca` that can connect to the database and has grants to insert
   tuples into a table named `log_table` defined as follows:

   ```
    Table "public.log_table"
 Column  |            Type             |                       Modifiers
---------|-----------------------------|--------------------------------------------------------
 pk      | integer                     | not null default nextval('log_table_pk_seq'::regclass)
 message | text                        |
 ts      | timestamp without time zone | default now()
Indexes:
    "log_table_pkey" PRIMARY KEY, btree (pk)
   ```

5. enable the log level to `DEBUG1` if you want to see the messages in the PostgreSQL logs:
   ```log_min_messages = debug1```


## Configuration
---

This module can be configured via hard-coded viariables, in particular:

```c
  char *log_table_database = "testdb";
  char *log_table_schema   = "public";
  char *log_table_name     = "log_table";
  char *log_table_message  = "STILL ALIVE and counting!";
  char *log_username       = "luca";
```

You can change the above variables depending on your installation in order to change the table, schema, username, log message and so on.
