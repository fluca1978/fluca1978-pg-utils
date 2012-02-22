#!/bin/sh

PGDATA=/postgresql/cluster1
DBOID=`oid2name -q | grep bsdmagdb | awk '{print $1;}'`
PAGE_SIZE=`expr 8 '*' 1024`
FILENODE=${PGDATA}/base/${DBOID}/${TABLEOID}
FILLFACTOR=100
PAGE_QUERY=" SELECT lp, lp_flags, t_xmin::text::int8 AS xmin, t_xmax::text::int8 AS xmax, t_ctid FROM heap_page_items( get_raw_page('magazine', 0) ) ORDER BY lp;"

echo "Cleaning the magazine table..."
psql -U bsdmag -c "TRUNCATE TABLE magazine;" bsdmagdb
psql -U bsdmag -c "VACUUM FULL magazine;" bsdmagdb
psql -U bsdmag -c "ALTER TABLE magazine SET (fillfactor=$FILLFACTOR);" bsdmagdb
TABLEOID=`oid2name -U bsdmag -t magazine -d bsdmagdb -q | awk '{print $1;}'`
FILENODE=${PGDATA}/base/${DBOID}/${TABLEOID}
ls -lh $FILENODE
SIZE_0=`ls -lk $FILENODE | awk '{print $5;}'`

sleep 2
echo "Inserting tuples..."
psql -U bsdmag -c "INSERT INTO magazine(id, title) VALUES( generate_series(1, 5000), 'vacuum-test');" bsdmagdb
psql -U bsdmag --pset pager=off -c "${PAGE_QUERY}" bsdmagdb
ls -lh $FILENODE
SIZE_1=`ls -lk $FILENODE | awk '{print $5;}'`
SIZE_TUPLE_1=`psql -U bsdmag -A -t -c "SELECT tuple_len FROM pgstattuple('magazine');" bsdmagdb`
SIZE_COUNT_1=`psql -U bsdmag -A -t -c "SELECT tuple_count FROM pgstattuple('magazine');" bsdmagdb`

sleep 2
echo "Updating tuples.."
psql -U bsdmag -c "UPDATE magazine SET title = 'UPDATED' || title; " bsdmagdb
psql -U bsdmag --pset pager=off -c "${PAGE_QUERY}" bsdmagdb
ls -lh $FILENODE
SIZE_2=`ls -lk $FILENODE | awk '{print $5;}'`
SIZE_TUPLE_2=`psql -U bsdmag -A -t -c "SELECT tuple_len FROM pgstattuple('magazine');" bsdmagdb`
SIZE_COUNT_2=`psql -U bsdmag -A -t -c "SELECT tuple_count FROM pgstattuple('magazine');" bsdmagdb`


sleep 2
echo "Deleting tuples.."
psql -U bsdmag -c "DELETE FROM magazine; " bsdmagdb
psql -U bsdmag --pset pager=off -c "${PAGE_QUERY}" bsdmagdb
ls -lh $FILENODE
SIZE_3=`ls -lk $FILENODE | awk '{print $5;}'`



echo "=========================="
SIZE_1_T=`expr $SIZE_1 / $SIZE_1`
SIZE_1_P=`expr $SIZE_1 / $PAGE_SIZE`
SIZE_2_T=`expr $SIZE_2 / $SIZE_1`
SIZE_2_P=`expr $SIZE_2 / $PAGE_SIZE`
SIZE_3_T=`expr $SIZE_3 / $SIZE_1`
SIZE_3_P=`expr $SIZE_3 / $PAGE_SIZE`


echo "Filenode was $FILENODE"
echo "Size before starting: $SIZE_0"
echo "Size after insert:    $SIZE_1 "
echo "     [ $SIZE_1_P pages with $SIZE_TUPLE_1 bytes for $SIZE_COUNT_1 live tuples]"
echo "Size after update:    $SIZE_2 "
echo "     [ $SIZE_2_P pages with $SIZE_TUPLE_2 bytes for $SIZE_COUNT_2 live tuples] (around $SIZE_2_T times initial size)"
echo "Size after delete:    $SIZE_3 [ $SIZE_3_P pages ] (around $SIZE_3_T times initial size)"
echo "=========================="



echo "=========================="
echo "Dump of the first data page"
psql -U bsdmag --pset pager=off -c "${PAGE_QUERY}" bsdmagdb
echo "=========================="

echo "=========================="
LAST_PAGE=`expr $SIZE_3_P - 1`
echo "Dump of the last data page $LAST_PAGE"
PAGE_QUERY_LAST=" SELECT lp, lp_flags, t_xmin::text::int8 AS xmin, t_xmax::text::int8  AS xmax, t_ctid FROM heap_page_items( get_raw_page('magazine', $LAST_PAGE ) ) ORDER BY lp LIMIT 5;"
psql -U bsdmag --pset pager=off -c "${PAGE_QUERY_LAST}" bsdmagdb
echo "=========================="