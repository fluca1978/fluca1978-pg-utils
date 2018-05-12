#!/bin/sh

ARCHIVING_PATH=$1
LOG=${ARCHIVING_PATH}/log.txt
NOW=$( date -R )

if [ $# -ne 3 ]
then
    echo "ERROR $NOW: $0 <archive_path> %f %p"
    exit 2
fi

WAL_SEGMENT=$2  # %f
SRC_FILE=$3     # file with path (%p)
DST_FILE=${ARCHIVING_PATH}/${WAL_SEGMENT}

# non sovrascrivo il file se esiste gia!
if [ -f ${DST_FILE} ]
then
    echo "KO $NOW: $WAL_SEGMENT already existing" >> $LOG
    exit 1
fi

cp ${SRC_FILE} ${DST_FILE} && echo "OK $NOW: WAL segment $WAL_SEGMENT archived" >> $LOG && exit 0
exit 1
