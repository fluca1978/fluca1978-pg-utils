#!/bin/sh

# Example script to perform a physical (low level)
# clone of a PostgreSQL instance.
#
# Invocation example:
# % sudo sh replication.backup.streaming.sh /mnt/data1/pgdata /mnt/clone/pgdata 'FLUCA' replication.streaming.recovery.conf

DATA_SRC=$1
DATA_DST=$2
LABEL=$3
RECOVERY_CONF=$4
CLONE_PORT=5433

if [ $# -eq 0 ]
then
    echo "Usage:"
    echo "$0 <source PGDATA> <destination PGDATA> [LABEL] [recovery.conf template]"
    echo "example: "
    echo "  $0 /mnt/data1/pgdata /mnt/clone/pgdata 'STREAMING' replication.streaming.recovery.conf"
    exit 2
fi



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
echo ""                             >> "$DATA_DST"/postgresql.conf
echo "# minimal slave conf from $0" >> "$DATA_DST"/postgresql.conf
echo "wal_level       = minimal"    >> "$DATA_DST"/postgresql.conf
echo "archive_mode    = off"        >> "$DATA_DST"/postgresql.conf
echo "max_wal_senders = 0"          >> "$DATA_DST"/postgresql.conf
echo "hot_standby     = on"         >> "$DATA_DST"/postgresql.conf
echo "log_destination = stderr "    >> "$DATA_DST"/postgresql.conf
echo "logging_collector = off "     >> "$DATA_DST"/postgresql.conf
echo "port = $CLONE_PORT "          >> "$DATA_DST"/postgresql.conf


echo "6) remove log files and other things on the clone..."
rm "$DATA_DST"/pg_log/*



grep -E "'^host\W+replication\W+$PGOWNER'" $DATA_SRC/pg_hba.conf
if [ $? -ne 0 ]
then
    echo "7) enable the master to accept the connection from the slave..."
    echo ""                                                   >> $DATA_SRC/pg_hba.conf
    echo "# line automatically inserted by $0"                >> $DATA_SRC/pg_hba.conf
    echo "host  replication  $PGOWNER    127.0.0.1/32  trust" >> $DATA_SRC/pg_hba.conf
fi

echo
echo "Ready to test"
echo "Edit $DATA_DST/recovery.conf (optionally $DATA_DST/postgresql.conf) and then"
echo "   sudo -u $PGOWNER pg_ctl -D $DATA_DST -o '-p $CLONE_PORT' start"
