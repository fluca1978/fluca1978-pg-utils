#/bin/sh

STANDBY_CLUSTER_NUMBER=$1
MASTER_CLUSTER=/postgresql/cluster1
DEST_CLUSTER=/postgresql/cluster${STANDBY_CLUSTER_NUMBER}
RECOVERY_FILE=$DEST_CLUSTER/recovery.conf
DEST_PORT=`psql -U bsdmag -A -t -c "SELECT setting FROM pg_settings WHERE name = 'port';" template1`
DEST_PORT=`expr $DEST_PORT + $STANDBY_CLUSTER_NUMBER`
echo "The stand-by node is listening on $DEST_PORT"
TEST_TABLE_NAME="test$$"
COUNT_QUERY_MAGAZINE="SELECT count(*) FROM magazine;"
COUNT_QUERY_TEST="SELECT count(*) FROM $TEST_TABLE_NAME;"

echo "Inserting tuples into the master node"
psql -U bsdmag -c "INSERT INTO magazine(id, title) VALUES(generate_series(1,10000), 'TEST-REPLICA');" bsdmagdb
echo "Tuples in the master node (magazine table)"
psql -U bsdmag -A -t -c "$COUNT_QUERY_MAGAZINE" bsdmagdb
psql -U bsdmag -c "CREATE TABLE $TEST_TABLE_NAME(pk serial NOT NULL, description text);" bsdmagdb
psql -U bsdmag -A -t -c "INSERT INTO $TEST_TABLE_NAME(pk, description) VALUES(generate_series(1,5000), 'NEW-TABLE-TEST');" bsdmagdb


echo "Activating the stand-by node..."
sleep 30
touch /postgresql/stand-by.${STANDBY_CLUSTER_NUMBER}.trigger
sleep 30

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