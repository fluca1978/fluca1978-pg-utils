/**
  * A function that is used to inspect a FreeBSD process to see if it has the
  * protection flag so that it will not be killed by the OOM killer.
  * It accepts a process ID (PID) to inspect, if set to NULL inspects the currently used
  * connection.
  *
  * It does internally creates a temporary table 'my_ps' that is not deleted to avoid problems
  * with other usage of the same function.
  *
  * Example of invocation:

    testdb=# set client_min_messages to debug;
  SET
  testdb=# select f_oomprotect();
  DEBUG:  Inspecting PostgreSQL process 4063
  NOTICE:  relation "my_ps" already exists, skipping
   f_oomprotect
  --------------
   t
  (1 row)

  */

    CREATE OR REPLACE FUNCTION
    f_oomprotect( pid int DEFAULT NULL )
    RETURNS boolean
    AS
    $CODE$
    DECLARE
      p_protected  bit(8)  = '00100000';
      is_protected boolean = false;
      shell        text;
    BEGIN
      -- if no pid supplied, use my own
      IF pid IS NULL OR pid < 0 THEN
        pid := pg_backend_pid();
      END IF;

      RAISE DEBUG 'Inspecting PostgreSQL process %', pid;

      shell :=    ' ps -ax -o flags,flags2 -p '
                    || pid
                    || ' | tail -n 1 ';
      CREATE TEMPORARY TABLE IF NOT EXISTS
                my_ps( flags bit(8), flags2 bit(8) );
      TRUNCATE my_ps;
      EXECUTE format( '  COPY my_ps( flags , flags2 ) FROM PROGRAM $$ %s $$ WITH ( DELIMITER $$ $$, FORMAT TEXT)', shell );


       SELECT ( flags & p_protected )::int > 0
       INTO is_protected
       FROM my_ps;

       RETURN is_protected;
    END
    $CODE$
    LANGUAGE plpgsql
    SECURITY DEFINER;
