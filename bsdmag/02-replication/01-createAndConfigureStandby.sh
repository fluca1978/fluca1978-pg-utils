#!/bin/sh

STANDBY_CLUSTER_NUMBER=$1
REPLICATION_MODE=$2
POSTGRESQL_ROOT=/postgresql
WAL_ARCHIVES=${POSTGRESQL_ROOT}/pitr
MASTER_CLUSTER=${POSTGRESQL_ROOT}/cluster1
DEST_CLUSTER=${POSTGRESQL_ROOT}/cluster${STANDBY_CLUSTER_NUMBER}
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf

HOST_IP=192.168.200.2
HOST_NET=192.168.200.0/24
REPLICATION_USER="replicator"
POSTGRESQL_CONF_TEMPLATE=/postgresql/postgresql.conf.template


REPLICATION_MODE_LOGSHIPPING="logshipping"
REPLICATION_MODE_LOGSTREAMING="logstreaming"
REPLICATION_MODE_HOTSTANDBY="hotstandby"

# A function to set up the file system for the standby node
# and to start the backup of the master cluster.
clone_master(){
# stop the cluster if running!
    /usr/local/bin/pg_ctl -D $DEST_CLUSTER stop >/dev/null 2>&1
    sleep 2
    rm -rf $DEST_CLUSTER
    mkdir  $DEST_CLUSTER
    chown pgsql:pgsql $DEST_CLUSTER
    chmod 700 $DEST_CLUSTER
    echo "Starting physical backup of the master node [$BACKUP_LABEL]"
    psql -U pgsql -c "SELECT pg_start_backup('REPLICA-$BACKUP_LABEL');" template1
    cp -R ${MASTER_CLUSTER}/* $DEST_CLUSTER
    rm -rf $DEST_CLUSTER/pg_xlog/* $DEST_CLUSTER/*.pid $DEST_CLUSTER/recovery.* $DEST_CLUSTER/*label*
    psql -U pgsql -c "SELECT pg_stop_backup();" template1
    echo "Physical backup of the master node [$BACKUP_LABEL] finished"

}

# Creates the recovery.conf file for the standby node in the case
# of the log shipping.
create_recovery_file_for_log_shipping(){
    rm $TRIGGER_FILE > /dev/null 2>&1
    echo "standby_mode='on'" > $RECOVERY_FILE
    echo "restore_command='cp $WAL_ARCHIVES/%f %p'" >> $RECOVERY_FILE
    echo "archive_cleanup_command='pg_archivecleanup $WAL_ARCHIVES %r'" >> $RECOVERY_FILE
    echo "trigger_file='$TRIGGER_FILE'" >> $RECOVERY_FILE
    
}

# Creates a replication user on the master node to allow standby to connect
# using such user to retrieve log WALs.
create_replication_user_on_master_if_not_exists(){
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
    
}


# Adds an entry in the pg_hba.conf file to allow the connection of the slave
# for the replication.
add_entry_pghba_if_not_exists(){
    grep $REPLICATION_USER ${MASTER_CLUSTER}/pg_hba.conf > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
	echo "adding an entry in the master pg_hba.conf"
	echo "host replication $REPLICATION_USER ${HOST_NET} trust" >> ${MASTER_CLUSTER}/pg_hba.conf
    fi

}


# Creates the recovery.conf file for the standby node in the case
# of the log streaming.
create_recovery_file_for_log_streaming(){
    rm $TRIGGER_FILE > /dev/null 2>&1
    echo "standby_mode='on'" > $RECOVERY_FILE
    echo "primary_conninfo=' host=$HOST_IP user=$REPLICATION_USER'" >> $RECOVERY_FILE
    echo "trigger_file='$TRIGGER_FILE'" >> $RECOVERY_FILE
}



adjust_standby_configuration(){
# adjust the port for the slave
    sed  -i .bak "s/#*port[ \t]*=[ \t]*\([0-9]*\)/port=$DEST_PORT/g"  $DEST_CLUSTER/postgresql.conf
# deactivate WAL archiving for the slave
    sed  -i .bak "s/wal_level[ \t]*=.*/wal_level='minimal'/g"  $DEST_CLUSTER/postgresql.conf
    sed  -i .bak "s/archive_mode[ \t]*=.*/archive_mode='off'/g"  $DEST_CLUSTER/postgresql.conf
    sed  -i .bak "s/max_wal_senders[ \t]*=.*/#max_wal_senders=0/g"  $DEST_CLUSTER/postgresql.conf
}


# Print some final instructions for the usage of the standby.
print_final_info(){
    echo "Standby node $STANDBY_CLUSTER_NUMBER will listen on port $DEST_PORT"
    echo "Execute the following command to change the status of the standby"
    echo "in order to accept incoming connections:"
    echo
    echo "      touch $TRIGGER_FILE            "
    echo
    echo "To manage the cluster use:"
    echo
    echo "      /usr/local/bin/pg_ctl -D $DEST_CLUSTER {start | stop}"
    echo
    echo "To run a workload please execute"
    echo
    echo "      sh 00-workload.sh $STANDBY_CLUSTER_NUMBER [activate | show]"
}


# check the number of arguments
if [ $# -lt 2 ]
then
    echo "Please specify the number of the cluster to configure and the replication mode!"
    exit
fi

# check to operate on a cluster different from the master one
if [ $STANDBY_CLUSTER_NUMBER -eq 1 ]
then
    echo "Cluster #1 is the master!"
    exit
fi


# compute on which TCP/IP port the standby will be accepting connections
DEST_PORT=`psql -U bsdmag -A -t -c "SELECT setting FROM pg_settings WHERE name = 'port';" template1`
DEST_PORT=`expr $DEST_PORT + $STANDBY_CLUSTER_NUMBER`

# where will be the recovery file for this standby node?
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf
# which recovery file to use to activate the node?
TRIGGER_FILE=/postgresql/standby.${STANDBY_CLUSTER_NUMBER}.trigger


# which kind of replication should I do?
case $REPLICATION_MODE in
    ${REPLICATION_MODE_LOGSHIPPING}) 
    echo "Log shipping replication"
    BACKUP_LABEL=${REPLICATION_MODE_LOGSHIPPING}
    # 1) clone the master into the standby directory filesystem
    clone_master
    # 2) create the recovery.conf file
    create_recovery_file_for_log_shipping    
    # 3) adjust the postgresql.conf file in the standby node
    adjust_standby_configuration
    ;;
    ${REPLICATION_MODE_LOGSTREAMING})
    echo "Log streaming replication"
    BACKUP_LABEL=${REPLICATION_MODE_LOGSTREAMING}
    # 1) clone the master into the standby directory filesystem
    clone_master
    # 2) create the recovery.conf file
    create_recovery_file_for_log_streaming   
    # 3) create the replication user on the master node
    create_replication_user_on_master_if_not_exists
    # 4) allow the standby node to connect back to the master to allow for replication
    add_entry_pghba_if_not_exists
    # 5) set the standby configuration to not ship logs
    adjust_standby_configuration
    ;;
    ${REPLICATION_MODE_HOTSTANDBY}) 
    echo "Hot standby replication"
    BACKUP_LABEL=${REPLICATION_MODE_HOTSTANDBY}
    ;;
    *)
	echo "Cannot procede without the replication method"
	exit
	;;
esac


print_final_info
exit    








#/usr/local/bin/pg_ctl -D $DEST_CLUSTER start