#!/bin/sh

STANDBY_CLUSTER_NUMBER=$1
MASTER_CLUSTER=/postgresql/cluster1
DEST_CLUSTER=/postgresql/cluster${STANDBY_CLUSTER_NUMBER}
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf

echo "Configuration for standby node $STANDBY_CLUSTER_NUMBER"

/usr/local/bin/pg_ctl -D $DEST_CLUSTER stop
rm -rf $DEST_CLUSTER
mkdir  $DEST_CLUSTER
chown pgsql:pgsql $DEST_CLUSTER
chmod 700 $DEST_CLUSTER
psql -U pgsql -c "SELECT pg_start_backup('REPLICA-LOG-SHIPPING');" template1
cp -R ${MASTER_CLUSTER}/* $DEST_CLUSTER
rm -rf $DEST_CLUSTER/pg_xlog/* $DEST_CLUSTER/*.pid
psql -U pgsql -c "SELECT pg_stop_backup();" template1
WAL_ARCHIVES=/postgresql/pitr
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf
TRIGGER_FILE=/postgresql/stand-by.${STANDBY_CLUSTER_NUMBER}.trigger
echo "stand-by_mode='on'" > $RECOVERY_FILE
echo "restore_command='cp $WAL_ARCHIVES/%f %p'" >> $RECOVERY_FILE
echo "archive_cleanup_command='pg_archivecleanup $WAL_ARCHIVES %r'" >> $RECOVERY_FILE
echo "trigger_file='$TRIGGER_FILE'" >> $RECOVERY_FILE
rm $TRIGGER_FILE > /dev/null 
DEST_PORT=`psql -U bsdmag -A -t -c "SELECT setting FROM pg_settings WHERE name = 'port';" template1`

DEST_PORT=`expr $DEST_PORT + $STANDBY_CLUSTER_NUMBER`
sed  -i .bak "s/#*port[ \t]*=[ \t]*\([0-9]*\)/port=$DEST_PORT/g"  $DEST_CLUSTER/postgresql.conf
echo "Standby node $STANDBY_CLUSTER_NUMBER will listen on port $DEST_PORT"
echo "Execute the following command to change the status of the standby"
echo "in order to accept incoming connections:"
echo "         touch $TRIGGER_FILE            "
echo
/usr/local/bin/pg_ctl -D $DEST_CLUSTER start