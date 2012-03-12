#/bin/sh


STANDBY_CLUSTER_NUMBER=$1
STANDBY_OPERATION=$2
POSTGRESQL_ROOT=/postgresql
WAL_ARCHIVES=${POSTGRESQL_ROOT}/pitr
MASTER_CLUSTER=${POSTGRESQL_ROOT}/cluster1
DEST_CLUSTER=${POSTGRESQL_ROOT}/cluster${STANDBY_CLUSTER_NUMBER}
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf
STANDBY_OPERATION_ACTIVATE="promote"
STANDBY_OPERATION_SHOWREPLICATION="show"


if [ $# -le 0 ]
then
    echo "Please specify the number of the cluster to configure!"
    echo
    echo "Usage: $0 <cluster-number> [ $STANDBY_OPERATION_ACTIVATE | $STANDBY_OPERATION_SHOWREPLICATION ]"
    exit
fi

if [ $# -eq 1 ]
then
    STANDBY_OPERATION=$STANDBY_OPERATION_ACTIVATE
fi


if [ $STANDBY_CLUSTER_NUMBER -eq 1 ]
then
    echo "Cluster #1 is the master!"
    exit
fi


    DEST_PORT=`psql -U bsdmag -A -t -c "SELECT setting FROM pg_settings WHERE name = 'port';" template1`
    DEST_PORT=`expr $DEST_PORT + $STANDBY_CLUSTER_NUMBER`


echo "Operating mode is $STANDBY_OPERATION"
echo "The stand-by node $STANDBY_CLUSTER_NUMBER is listening on $DEST_PORT"



TEST_TABLE_NAME="test$$"
COUNT_QUERY_MAGAZINE="SELECT count(*) FROM magazine;"
COUNT_QUERY_TEST="SELECT count(*) FROM $TEST_TABLE_NAME;"

echo "Inserting tuples into the master node"
psql -U bsdmag -c "TRUNCATE TABLE magazine;" bsdmagdb
psql -U bsdmag -c "INSERT INTO magazine(id, title) VALUES(generate_series(1,1000000), 'TEST-REPLICA');" bsdmagdb
echo "Tuples in the master node (magazine table)"
psql -U bsdmag -A -t -c "$COUNT_QUERY_MAGAZINE" bsdmagdb
psql -U bsdmag -c "CREATE TABLE $TEST_TABLE_NAME(pk serial NOT NULL, description text);" bsdmagdb
psql -U bsdmag -A -t -c "INSERT INTO $TEST_TABLE_NAME(pk, description) VALUES(generate_series(1,500000), 'NEW-TABLE-TEST');" bsdmagdb



if [ "$STANDBY_OPERATION" = "$STANDBY_OPERATION_ACTIVATE" ]
then
    echo "Activating the stand-by node..."
    sleep 30
    touch /postgresql/standby.${STANDBY_CLUSTER_NUMBER}.trigger
    sleep 10
    echo "=========================================="
    echo "Tuples in the master node (magazine table)"
    psql -U bsdmag -A -t -c "$COUNT_QUERY_MAGAZINE" bsdmagdb
    echo "Tuples in the master node (test table)"
    psql -U bsdmag -A -t -c "$COUNT_QUERY_TEST" bsdmagdb
    echo "=========================================="
    echo "Tuples in the slave node (magazine table)"
    psql -U bsdmag -A -t -p $DEST_PORT -c "$COUNT_QUERY_MAGAZINE" bsdmagdb
    echo "Tuples in the slave node (test table)"
    psql -U bsdmag -A -t -p $DEST_PORT -c "$COUNT_QUERY_TEST" bsdmagdb
    echo "=========================================="
else
    if [ "$STANDBY_OPERATION" = "$STANDBY_OPERATION_SHOWREPLICATION" ]
    then
    

	WAL_DIFFERENCE=1
	while [ $WAL_DIFFERENCE -gt 0 ]
	do
	    
	    echo "Showing replica information"
	    # show log shipping processes
	    echo "====== MASTER ======="
	    pgrep -f -l -i archiver 
	    pgrep -f -l -i postgres | grep sender 
	    echo "====================="
	    echo "====== STANDBY ======="
	    pgrep -f -l -i startup
	    pgrep -f -l -i postgres | grep receiver
	    echo "====================="
	    
	    
	    MASTER_XLOG_LOCATION=`psql -U pgsql -A -t -c "SELECT pg_current_xlog_location();" template1 | sed 's|[0-9]/\([0-9]\)*||g'`
	    STANDBY_XLOG_LOCATION=`psql -U pgsql -p $DEST_PORT -A -t -c "SELECT pg_last_xlog_replay_location();" template1 | sed 's|[0-9]/\([0-9]\)*||g'`
	    
	    
	    obase=10
	    ibase=16
	    export obase
	    export ibase
	    MASTER_XLOG_LOCATION_10=`echo $MASTER_XLOG_LOCATION | bc`
	    STANDBY_XLOG_LOCATION_10=`echo $STANDBY_XLOG_LOCATION | bc`
	    echo "xlog location: master  $MASTER_XLOG_LOCATION  ($MASTER_XLOG_LOCATION_10)"
	    echo "xlog location: standby $STANDBY_XLOG_LOCATION ($STANDBY_XLOG_LOCATION_10)"
	    WAL_DIFFERENCE=`expr $MASTER_XLOG_LOCATION_10 - $STANDBY_XLOG_LOCATION_10`
	    echo "Difference is $WAL_DIFFERENCE"
	done

    fi
fi
