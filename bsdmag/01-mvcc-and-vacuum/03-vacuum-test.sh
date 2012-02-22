#!/bin/sh

PGDATA=/postgresql/cluster1
DBOID=`oid2name -q | grep bsdmagdb | awk '{print $1;}'`
PAGE_SIZE=`expr 8 '*' 1024`
TABLEOID=`oid2name -U bsdmag -t magazine -d bsdmagdb -q | awk '{print $1;}'`
FILENODE=${PGDATA}/base/${DBOID}/${TABLEOID}

echo "Cleaning the magazine table..."
ls -lh $FILENODE
SIZE_1=`ls -lk $FILENODE | awk '{print $5;}'`

psql -U bsdmag -c "VACUUM FULL VERBOSE magazine; " bsdmagdb
ls -lh $FILENODE
SIZE_2=`ls -lk $FILENODE | awk '{print $5;}'`


echo "=========================="
SIZE_1_T=`expr $SIZE_1 / $SIZE_1`
SIZE_1_P=`expr $SIZE_1 / $PAGE_SIZE`
SIZE_2_T=`expr $SIZE_2 / $SIZE_1`
SIZE_2_P=`expr $SIZE_2 / $PAGE_SIZE`

echo "Filenode was $FILENODE"
echo "Size before starting: $SIZE_1"
echo "Size after VACUUM:    $SIZE_2 [ $SIZE_2_P pages ] (around $SIZE_2_T times initial size)"
echo "=========================="