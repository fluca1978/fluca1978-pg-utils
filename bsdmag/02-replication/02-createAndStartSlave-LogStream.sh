#!/bin/sh


STANDBY_CLUSTER_NUMBER=$1
MASTER_CLUSTER=/postgresql/cluster1
DEST_CLUSTER=/postgresql/cluster${STANDBY_CLUSTER_NUMBER}
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf
HOST_IP=192.168.200.2
HOST_NET=192.168.200.0/24
REPLICATION_USER="replicator"
POSTGRESQL_CONF_TEMPLATE=/postgresql/postgresql.conf.template

rm -rf $DEST_CLUSTER
mkdir  $DEST_CLUSTER
chown pgsql:pgsql $DEST_CLUSTER
chmod 700 $DEST_CLUSTER
psql -U pgsql -c "SELECT pg_start_backup('REPLICA-1');" template1
cp -R ${MASTER_CLUSTER}/* $DEST_CLUSTER
rm -rf $DEST_CLUSTER/pg_xlog/* $DEST_CLUSTER/*.pid
cp $POSTGRESQL_CONF_TEMPLATE $DEST_CLUSTER/postgresql.conf
psql -U pgsql -c "SELECT pg_stop_backup();" template1

psql -U pgsql -c "CREATE USER $REPLICATION_USER SUPERUSER LOGIN CONNECTION LIMIT 1 PASSWORD 'replicator';" template1
echo "host replication $REPLICATION_USER ${HOST_NET} trust" >> ${MASTER_CLUSTER}/pg_hba.conf


WAL_ARCHIVES="/postgresql/pitr"
RECOVERY_FILE="$DEST_CLUSTER/recovery.conf"
TRIGGER_FILE="/postgresql/stand-by.${STANDBY_CLUSTER_NUMBER}.trigger"
echo "stand-by_mode='on'" > $RECOVERY_FILE
echo "primary_conninfo=' host=$HOST_IP user=$REPLICATION_USER'" >> $RECOVERY_FILE
echo "trigger_file='$TRIGGER_FILE'" >> $RECOVERY_FILE
rm $TRIGGER_FILE


DEST_PORT=`psql -U bsdmag -A -t -c "SELECT setting FROM pg_settings WHERE name = 'port';" template1`
DEST_PORT=`expr $DEST_PORT + $STANDBY_CLUSTER_NUMBER`
echo "port = $DEST_PORT" >> $DEST_CLUSTER/postgresql.conf
/usr/local/bin/pg_ctl -D $DEST_CLUSTER start