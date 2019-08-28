
/**
 * A function to compute the amount of working hours in a specific month/year.
 *
 * @param _year the year or NULL to use the current year
 * @param _month the month or NULL to use the current month
 * @param _saturday true to include saturdays as a working day
 * @param _hour_template the amount of hours for every day of week (as 'dow'), the first value (sunday) is always skipped. If not specified, 8 hours per day are assumed on every day.
 * @param _exclude_days the effective days to exclude from the month, as 'day of month'.
 *
 * @return the sum of the working hour
 *
 * Use 'DEBUG' messages to provide a log of what is computed.
 *
 * Example of possible invocation:

testdb=# SELECT compute_working_hours( NULL, NULL, true, NULL,  ARRAY[12, 15 ,29] );
DEBUG:  Working days in the range [2019-08-01,2019-09-01)
DEBUG:  Day 2019-08-01 counting 8 working hours
DEBUG:  Day 2019-08-02 counting 8 working hours
DEBUG:  Day 2019-08-03 counting 8 working hours
...
 compute_working_hours
-----------------------
                   192

 */

CREATE OR REPLACE FUNCTION compute_working_hours( _year int,
                                                  _month int,
                                                  _saturday boolean DEFAULT false,
                                                  _hour_template int[] DEFAULT ARRAY[ 8, 8, 8, 8, 8, 8, 8 ]::int[],
                                                  _exclude_days int[] DEFAULT null )
RETURNS int
AS $CODE$
DECLARE
  _exclude_days_as_dates date[];
  current_index int;
BEGIN
  -- check arguments
  IF _year IS NULL THEN
     _year := extract( year FROM CURRENT_DATE );
  END IF;

  IF _month IS NULL THEN
     _month := extract( month FROM CURRENT_DATE );
  END IF;

  IF _exclude_days IS NOT NULL THEN
    FOR current_index IN 1 .. array_upper( _exclude_days, 1 ) LOOP
     _exclude_days_as_dates := array_append( _exclude_days_as_dates,
                                             make_date( _year, _month, _exclude_days[ current_index ] ) );
    END LOOP;
  END IF;

  RETURN compute_working_hours( make_date( _year, _month, 1),
                              ( make_date( _year, _month, 1) + '1 month - 1 day'::interval )::date,
                                _saturday,
                                _hour_template,
                                _exclude_days_as_dates );

END
$CODE$
LANGUAGE plpgsql;




/**
 * Computes the sum of working hour between two dates.
 *
 * @param begin_day the start date (inclusive)
 * @param end_day the end date (inclusive)
 * @param _saturday true if saturdays must be accounted
 * @param _hour_template an array of working hours per day (7) as of 'dow' (day of week).
 *                       Since sundays are always excluded, the first value of the array
 *                       is never considered.
 * @param _exclude_days an array of dates to be excluded
 *
 * @returns the sum of working hour
 *
 * Use the 'DEBUG' message level to provide information about the execution.
 *
 * Example of invocation:

testdb=# select compute_working_hours( current_date, current_date + 3, false, NULL, ARRAY[ '2019-08-28' ]::date[] );
DEBUG:  Working days in the range [2019-08-28,2019-09-01)
DEBUG:  Day 2019-08-28 counting 0 working hours
DEBUG:  Day 2019-08-29 counting 8 working hours
DEBUG:  Day 2019-08-30 counting 8 working hours
DEBUG:  Day 2019-08-31 counting 0 working hours
compute_working_hours
-----------------------
                    16

*/
CREATE OR REPLACE FUNCTION compute_working_hours( begin_day DATE,
                                                  end_day DATE,
                                                  _saturday boolean DEFAULT false,
                                                  _hour_template int[] DEFAULT ARRAY[ 8, 8, 8, 8, 8, 8, 8 ]::int[],
                                                  _exclude_days date[] DEFAULT NULL )
RETURNS INT
AS $CODE$
DECLARE
  working_hours int := 0;
  working_days daterange;
  current_day date;
  current_day_hours int;
  skip boolean;
BEGIN
  -- check arguments
  IF begin_day IS NULL
     OR end_day IS NULL
     OR begin_day >= end_day THEN
     RAISE EXCEPTION 'Please check dates';
  END IF;


  IF _hour_template IS NULL THEN
     _hour_template := ARRAY[ 8, 8, 8, 8, 8, 8, 8 ]::int[];
  END IF;
  WHILE array_length( _hour_template, 1 ) < 7 LOOP
    _hour_template := array_append( _hour_template, 8 );
  END LOOP;

   -- create the working period date range
  working_days = daterange( begin_day, end_day, '[]');

  RAISE DEBUG 'Working days in the range %', working_days;

  current_day := lower( working_days );
  LOOP
     -- skip sundays
     skip := EXTRACT( dow FROM current_day ) = 0;
     -- skip saturdays if required
     skip := skip OR  ( NOT _saturday AND EXTRACT( dow FROM current_day ) = 6 );

     -- skip this particular day if specified
     skip := skip OR ( _exclude_days IS NOT NULL AND _exclude_days @> ARRAY[ current_day ] );

     IF NOT skip THEN
        current_day_hours := _hour_template[ EXTRACT( dow FROM current_day ) ];
     ELSE
        current_day_hours := 0;
     END IF;

     RAISE DEBUG 'Day % counting % working hours',
                 current_day,
                 current_day_hours;

     working_hours := working_hours + current_day_hours;
     current_day   := current_day + 1;
     EXIT WHEN NOT current_day <@ working_days;
  END LOOP;


  -- all done
  RETURN working_hours;


END
$CODE$
LANGUAGE plpgsql;
