#!/bin/sh


STANDBY_CLUSTER_NUMBER=$1
POSTGRESQL_ROOT=/postgresql
WAL_ARCHIVES=${POSTGRESQL_ROOT}/pitr
MASTER_CLUSTER=${POSTGRESQL_ROOT}/cluster1
DEST_CLUSTER=${POSTGRESQL_ROOT}/cluster${STANDBY_CLUSTER_NUMBER}
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf
HOST_IP=192.168.200.2
HOST_NET=192.168.200.0/24
REPLICATION_USER="replicator"
POSTGRESQL_CONF_TEMPLATE=/postgresql/postgresql.conf.template


if [ $# -le 0 ]
then
    echo "Please specify the number of the cluster to configure!"
    exit
fi

if [ $STANDBY_CLUSTER_NUMBER -eq 1 ]
then
    echo "Cluster #1 is the master!"
    exit
fi


echo "Configuration for standby node $STANDBY_CLUSTER_NUMBER"

# stop the cluster if running!
/usr/local/bin/pg_ctl -D $DEST_CLUSTER stop >/dev/null 2>&1
sleep 2
rm -rf $DEST_CLUSTER
mkdir  $DEST_CLUSTER
chown pgsql:pgsql $DEST_CLUSTER
chmod 700 $DEST_CLUSTER
psql -U pgsql -c "SELECT pg_start_backup('REPLICA-LOG-STREAM');" template1
cp -R ${MASTER_CLUSTER}/* $DEST_CLUSTER
rm -rf $DEST_CLUSTER/pg_xlog/* $DEST_CLUSTER/*.pid $DEST_CLUSTER/recovery.* $DEST_CLUSTER/*label*
psql -U pgsql -c "SELECT pg_stop_backup();" template1

RECOVERY_FILE=$DEST_CLUSTER/recovery.conf
TRIGGER_FILE=/postgresql/standby.${STANDBY_CLUSTER_NUMBER}.trigger
rm $TRIGGER_FILE > /dev/null 2>&1

echo "standby_mode='on'" > $RECOVERY_FILE
echo "primary_conninfo=' host=$HOST_IP user=$REPLICATION_USER'" >> $RECOVERY_FILE
echo "trigger_file='$TRIGGER_FILE'" >> $RECOVERY_FILE



# check if the replication user exists and has the replication capabilities
REPLICATION_USER_EXISTS=`psql -U pgsql -A -t -c "SELECT rolreplication FROM pg_roles WHERE rolname = '$REPLICATION_USER';" template1`


if [ -z "$REPLICATION_USER_EXISTS" ]
then
    echo "Creating the replication user $REPLICATION_USER"
    psql -U pgsql -c "CREATE USER $REPLICATION_USER WITH REPLICATION LOGIN CONNECTION LIMIT 1 PASSWORD '$REPLICATION_USER';" template1
    
else
    if [ $REPLICATION_USER_EXISTS = "t" ]
    then
	echo "Replication user $REPLICATION_USER already exists on the master cluster!"
    else
	if [ $REPLICATION_USER_EXISTS = "f" ]
	then
	    echo "Replication user $REPLICATION_USER already exists but does not have replication capabilities! Altering the role..."
	    psql -U pgsql -c "ALTER ROLE $REPLICATION_USER WITH REPLICATION;" template1
	    
	fi
	
    fi
fi


# check that the pg_hba.conf file of the master cluster has
# the required entry to allow for replication
echo "Checking pg_hba.conf for the master cluster"
grep $REPLICATION_USER ${MASTER_CLUSTER}/pg_hba.conf > /dev/null 2>&1
if [ $? -ne 0 ]
then
    echo "adding an entry in the master pg_hba.conf"
    echo "host replication $REPLICATION_USER ${HOST_NET} trust" >> ${MASTER_CLUSTER}/pg_hba.conf
fi





# reconfigure the standby to not ship logs
DEST_PORT=`psql -U bsdmag -A -t -c "SELECT setting FROM pg_settings WHERE name = 'port';" template1`

DEST_PORT=`expr $DEST_PORT + $STANDBY_CLUSTER_NUMBER`
# adjust the port for the slave
sed  -i .bak "s/#*port[ \t]*=[ \t]*\([0-9]*\)/port=$DEST_PORT/g"  $DEST_CLUSTER/postgresql.conf
# deactivate WAL archiving for the slave
sed  -i .bak "s/wal_level[ \t]*=.*/wal_level='minimal'/g"  $DEST_CLUSTER/postgresql.conf
sed  -i .bak "s/archive_mode[ \t]*=.*/archive_mode='off'/g"  $DEST_CLUSTER/postgresql.conf
sed  -i .bak "s/max_wal_senders[ \t]*=.*/#max_wal_senders=0/g"  $DEST_CLUSTER/postgresql.conf

echo "Standby node $STANDBY_CLUSTER_NUMBER will listen on port $DEST_PORT"
echo "Execute the following command to change the status of the standby"
echo "in order to accept incoming connections:"
echo
echo "      touch $TRIGGER_FILE            "
echo
echo "To manage the cluster use:"
echo
echo "      /usr/local/bin/pg_ctl -D $DEST_CLUSTER {start|stop}"
echo
echo "To run a workload please execute"
echo
echo "      sh 00-workload.sh $STANDBY_CLUSTER_NUMBER"
/usr/local/bin/pg_ctl -D $DEST_CLUSTER start