#!/bin/sh

# Example script to perform a physical (low level)
# clone of a PostgreSQL instance.
#
# Invocation example:
# % sudo sh replication.backup.sh /mnt/data1/pgdata /mnt/clone/pgdata 'FLUCA' replication.pitr.recovery.conf

DATA_SRC=$1
DATA_DST=$2
LABEL=$3
RECOVERY_CONF=$4

if [ ! $# -ge 2 ]
then
    echo "$0 <source data dir> <dest data dir> [label]"
    exit 2;
fi


if [ ! -d "$DATA_SRC"  ]
then
    echo "Cannot work against $DATA_SRC"
    exit 1
fi

if [ -d "$DATA_DST" ]
then
    echo "Directory [$DATA_DST] already exists!"
    exit 1
fi

if [ -z "$LABEL" ]
then
    LABEL=`basename $0`
fi

# this should have been done with `stat`, but its format
# is not portable across different Unix-like!
PGOWNER=`ls -ld "$DATA_SRC" | awk '{ print $3; }'`
PGGROUP=`ls -ld "$DATA_SRC" | awk '{ print $4; }'`

echo "[$LABEL] from [$DATA_SRC] -> [$DATA_DST] by [$PGOWNER:$PGGROUP]"
sleep 5


mkdir -p "$DATA_SRC"

QUERY=` cat <<EOF
SELECT
    pg_start_backup( '$LABEL'  -- backup label
                     , true    -- start immediatly, do WAL activity
                     , true    -- exclusive
                   );
EOF`

echo "1) Executing $QUERY "
psql -X -h localhost -U postgres -d template1 -c "$QUERY"
sleep 5
echo "2) rsync $DATA_SRC -> $DATA_DST"
rsync -av "$DATA_SRC/" "$DATA_DST/" --exclude="postmaster.pid" --exclude="postmaster.opts" --exclude="replication.*" > /dev/null

if [ -f "$RECOVERY_CONF" ]
then
    echo "2a) copy recovery.conf"
    cp "$RECOVERY_CONF" "$DATA_DST"/recovery.conf
fi

echo "3) Adjust owner to $PGOWNER:$PGGROUP"
chown -R $PGOWNER:$PGGROUP "$DATA_DST"



QUERY=`cat  <<EOF
SELECT pg_stop_backup( true );
EOF`
echo "4) Executing $QUERY"
psql -X -h localhost -U postgres -d template1 -c "$QUERY"

echo "5) disable some features on the clone..."
echo "" >> "$DATA_DST"/postgresql.conf
echo "# just for test when playing with replication..."
echo "log_destination = stderr " >> "$DATA_DST"/postgresql.conf
echo "loggin_collector = off " >> "$DATA_DST"/postgresql.conf
echo "port = 5433 " >> "$DATA_DST"/postgresql.conf

echo "Ready to test"
echo "Edit $DATA_DST/recovery.conf and then"
echo "   sudo -u postgres pg_ctl -D $DATA_DST -o '-p 5433' start"
