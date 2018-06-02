#include "postgres.h"

/* These are always necessary for a bgworker */
#include "miscadmin.h"
#include "postmaster/bgworker.h"
#include "storage/ipc.h"
#include "storage/latch.h"
#include "storage/lwlock.h"
#include "storage/proc.h"
#include "storage/shmem.h"

/* these headers are used by this particular worker's code */
#include "access/xact.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "lib/stringinfo.h"
#include "pgstat.h"
#include "utils/builtins.h"
#include "utils/snapmgr.h"
#include "tcop/utility.h"

PG_MODULE_MAGIC;

void		_PG_init(void);

/* flags set by signal handlers */
static volatile sig_atomic_t sigterm_activated = false;



static void
sighup_handler( SIGNAL_ARGS )
{
	int	caught_errno = errno;
	if (MyProc)
		SetLatch(&MyProc->procLatch);

  /* restore original errno */
	errno = caught_errno;
}

static void
sigterm_handler( SIGNAL_ARGS )
{
  sighup_handler( postgres_signal_arg );
  sigterm_activated = true;
}


/*
 * Main worker function, called when the worker has been registrated and activated.
 *
 * Example of the log output:
 *

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

 *
 * In order to signal the process:
 *

 % ps -auxw | grep alive_worker
 postgres 3312   0.0  5.4 201368 26636  -  Ss   15:07     0:00.01 postgres: bgworker: alive worker    (postgres)
 % sudo kill -TERM 3312

 *
 * and the process will print in the log:

 DEBUG:  worker process: alive worker (PID 3312) exited with exit code 0
 DEBUG:  unregistering background worker "alive worker"

 *
 * While running the process will put a new tuple into the "public.log_table" table, so that it will be populated
 * as follows:

 > SELECT * FROM log_table;
 pk |           message            |             ts
----+------------------------------+----------------------------
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

 *
 */
static void
worker_main( Datum main_arg )
{
  /*
   * StringInfo is a C structure that represents an extendible string,
   * and it has the fields:
   * - data -> the actual string
   * - maxlen -> the max length of the string
   * - len -> the actual len of the string
   * - cursor -> not used but internally
   */
	StringInfoData queryStringData;
	initStringInfo( &queryStringData );


  /*
   * Variables used to drive the behavior of this
   * worker process. They should be placed as GUC variables,
   * but this is out of the scope of the example.
   */
  char *log_table_database = "testdb";
  char *log_table_schema   = "public";
  char *log_table_name     = "log_table";
  char *log_table_message  = "STILL ALIVE and counting!";
  char *log_username       = "luca";
  int  log_entry_counter   = 0;



	elog( DEBUG1, "starting alive_worker::worker_main" );


  /*
   * When a worker starts it has signal blocked, this
   * allows for the worker to set up its own signal handlers
   * and then to unblock signals
   */

	pqsignal( SIGHUP,  sighup_handler );
	pqsignal( SIGTERM, sigterm_handler );
  sigterm_activated = false;
	BackgroundWorkerUnblockSignals();

	/* Connect to our database */
	BackgroundWorkerInitializeConnection( log_table_database,
                                        log_username );

	/*
	 * Main loop: do this until the SIGTERM handler tells us to terminate
	 */
	while ( ! sigterm_activated )
	{
		int	ret;
		int	rc;

    elog( DEBUG1, "alive_worker in main loop" );

		/*
		 * Background workers mustn't call usleep() or any direct equivalent:
		 * instead, they may wait on their process latch, which sleeps as
		 * necessary, but is awakened if postmaster dies.  That way the
		 * background process goes away immediately in an emergency.
		 */
		rc = WaitLatch( &MyProc->procLatch,
					          WL_LATCH_SET | WL_TIMEOUT | WL_POSTMASTER_DEATH,
                    10000L ); /* 10 secondi */
		ResetLatch( &MyProc->procLatch );

    /*
     * in the special case the latch resumed me and the postmaster
     * died I need to exit immediatly !
     */
		if ( rc & WL_POSTMASTER_DEATH )
			proc_exit( 1 );


		/*
		 * Start a transaction on which we can run queries.  Note that each
		 * StartTransactionCommand() call should be preceded by a
		 * SetCurrentStatementStartTimestamp() call, which sets both the time
		 * for the statement we're about the run, and also the transaction
		 * start time.	Also, each other query sent to SPI should probably be
		 * preceded by SetCurrentStatementStartTimestamp(), so that statement
		 * start time is always up to date.
		 *
		 * The SPI_connect() call lets us run queries through the SPI manager,
		 * and the PushActiveSnapshot() call creates an "active" snapshot
		 * which is necessary for queries to have MVCC data to work on.
		 *
		 * The pgstat_report_activity() call makes our activity visible
		 * through the pgstat views.
		 */
		SetCurrentStatementStartTimestamp();
		StartTransactionCommand();
		SPI_connect();
		PushActiveSnapshot( GetTransactionSnapshot() );
		pgstat_report_activity( STATE_RUNNING, queryStringData.data );

    /*
     * Prepare to execute the query via SPI.
     * The queryStringDatafer will build a query like:
     *
     *
     * INSERT INTO public.log_table( message )
     * VALUES( 'STILL ALIVE and counting! 1' )
     *
     */
		resetStringInfo( &queryStringData );
		appendStringInfo( &queryStringData,
                      "INSERT INTO %s.%s( message ) "
                      "VALUES( '%s %d' ) ",
                      log_table_schema,
                      log_table_name,
                      log_table_message,
                      ++log_entry_counter );


		elog( DEBUG1, "alive_worker executing query [%s] by [%s]",
          queryStringData.data,
          log_username );

		ret = SPI_execute( queryStringData.data, /* query to execute */
                       false,                /* not readonly query */
                       0 );                  /* no count limit */

    switch ( ret ){
    case SPI_OK_INSERT:
      elog( DEBUG1, "alive_worker query OK!" );
      break;

    case SPI_OK_SELECT:
    case SPI_OK_SELINTO:
    case SPI_OK_DELETE:
    case SPI_OK_UPDATE:
    case SPI_OK_INSERT_RETURNING:
    case SPI_OK_DELETE_RETURNING:
    case SPI_OK_UPDATE_RETURNING:
    case SPI_OK_UTILITY:
    case SPI_OK_REWRITTEN:
      elog( WARNING, "alive_worker obtained success [%d] not understood!", ret );
      break;

    case SPI_ERROR_ARGUMENT:
    case SPI_ERROR_COPY:
    case SPI_ERROR_TRANSACTION:
    case SPI_ERROR_OPUNKNOWN:
    case SPI_ERROR_UNCONNECTED:
      elog( FATAL, "alive_worker query KO! Return code is [%d]", ret );
      break;

    default:
      elog( FATAL, "alive_worker SPI return code unknown [%d]", ret );
    }

		if ( ret != SPI_OK_INSERT )
			elog( FATAL, "alive_worker cannot execute query, error code [%d]", ret );


		/*
		 * And finish our transaction.
		 */
		SPI_finish();
		PopActiveSnapshot();
		CommitTransactionCommand();
		pgstat_report_activity( STATE_IDLE, NULL );
	}

	proc_exit(0);
}

/*
 * Entrypoint of this module.
 * Register the module so that PostgreSQL can start the process.
 *
 */
void
_PG_init(void)
{
	BackgroundWorker worker;

	/* set up worker data */
	worker.bgw_flags        = BGWORKER_SHMEM_ACCESS
                            | BGWORKER_BACKEND_DATABASE_CONNECTION;
	worker.bgw_start_time   = BgWorkerStart_RecoveryFinished;
	worker.bgw_restart_time = BGW_NEVER_RESTART;
	worker.bgw_main         = worker_main;
	snprintf(worker.bgw_name, BGW_MAXLEN, "alive worker");

  /*
   * Since 9.4 there must be a pid to notify, or in the logs
   * there will be an entry as
   *
   * LOG:  background worker "alive worker": only dynamic background workers can request notification
   */
  worker.bgw_notify_pid   = 0;

  elog( INFO, "alive_worker::_PG_init registering worker [%s]", worker.bgw_name );

	/* register worker */
	RegisterBackgroundWorker(&worker);
}
