#!/bin/sh

PGBENCH_CMD=$( which pgbench )
PGBENCH_DB='pgbench'
PGBENCH_PARALLELISM=4
PSQL_CMD=$( which psql )
PGBENCH_HOST=localhost

help(){
    cat <<EOF
Usage:
  $0 <num> [<time>] [<host>] [<tag>]
where
  num   is the number of tests to run
  time  how many seconds to run each test (default 12 minutes)
  host  remote host (default to localhost)
  tag   is a tag to use for identifying the log files
EOF
}


# check if the command is present
if [ -z "$PGBENCH_CMD" -o  ! -x "$PGBENCH_CMD" ]; then
    echo "Cannot find the command `pgbench`!"
    exit 1
else
    echo "Using pgbench executable [$PGBENCH_CMD]"
fi

if [ -z "$PSQL_CMD" ]; then
    echo "Cannot find psql executable"
    exit 1
fi

# check to have a number to run
PGBENCH_RUNS=$1
if [ -z "$PGBENCH_RUNS" -o ! $(( PGBENCH_RUNS + 0 )) ];
then
    help
    exit
fi

# check to have time to run
PGBENCH_TIME=$2
if [ -z "$PGBENCH_TIME" -o ! $(( PGBENCH_TIME + 0 )) ]; then
    PGBENCH_TIME=720 #12 minutes
fi


PGBENCH_HOST=$3
if [ -z "PGBENCH_HOST" ]; then
    PGBENCH_HOST=localhost
fi

# do we have a tag?
PGBENCH_TAG="$4"
if [ -z "$PGBENCH_TAG" ]; then
    PGBENCH_TAG="test"
fi

current_run=1
current_tps_total=0
current_latency_total=0
PGBENCH_LOG="pgbench-$PGBENCH_TAG.log"
echo "Log in [$PGBENCH_LOG]"

echo "=== pgbench test run from $0 ===" > $PGBENCH_LOG

# check for configuration
$PSQL_CMD  -c "SELECT name, setting FROM pg_settings WHERE name IN ('checkpoint_completion_target', 'shared_buffers', 'checkpoint_timeout', 'fsync', 'synchronous_commit' );" -h $PGBENCH_HOST $PGBENCH_DB >> $PGBENCH_LOG


while [ $current_run -le $PGBENCH_RUNS ]
do
    current_log=/tmp/pgbench.$$.$current_run
    echo "Running test $current_run with log $current_log"
    $PGBENCH_CMD  -T $PGBENCH_TIME  -j $PGBENCH_PARALLELISM -c $PGBENCH_PARALLELISM -h $PGBENCH_HOST $PGBENCH_DB > $current_log 2>&1
    current_tps=$( grep 'tps = ' $current_log | grep 'including' | awk '{printf "%d", $3;}')
    current_latency=$( grep 'latency' $current_log | awk '{printf "%d", $4;}' )

    current_tps_total=$(( current_tps_total + current_tps ))
    current_latency_total=$(( current_latency_total + current_latency ))
    echo "Run $current_run: tps = $current_tps, latency = $current_latency ms" >> $PGBENCH_LOG
    current_run=$(( current_run + 1 ))
done

echo "please note all numbers are rounded to integers"
echo "all done!"
echo "=============================================="
echo "tps avg = " $(( current_tps_total / PGBENCH_RUNS ))
echo "latency avg ms = " $(( current_latency_total / PGBENCH_RUNS ))
echo "=============================================="
rm /tmp/pgbench.$$.*
