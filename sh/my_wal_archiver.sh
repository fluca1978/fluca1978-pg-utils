#!/bin/sh

ARCHIVING_PATH=/mnt/data2/wal_archive
LOG=${ARCHIVING_PATH}/log.txt
NOW=$( date -R )

if [ $# -ne 2 ]
then
    echo "ERROR $NOW: $0 %f %p"
    exit 2
fi

SRC_FILE=$2 # file with path
DST_FILE=${ARCHIVING_PATH}/$1

# non sovrascrivo il file se esiste gia!
if [ -f ${DST_FILE} ]
then
    echo "KO $NOW: $1 esiste gia'" >> $LOG
    exit 1
fi

cp ${SRC_FILE} ${DST_FILE} && echo "OK $NOW: WAL segment $1 copiato" >> $LOG && exit 0
exit 1
