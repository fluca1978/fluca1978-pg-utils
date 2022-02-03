#!/bin/sh

LOGGER_TAG=pgagroal

# check arguments
if [ $# -ne 4 ]; then
    logger -s -t $LOGGER_TAG "Automatic failover script requires four arguments [$@]"
    exit 1
fi


PRIMARY_HOSTNAME=$1
PRIMARY_PORT=$2
STANDBY_HOSTNAME=$3
STANDBY_PORT=$4

STANDBY_PGDATA=/postgres/14/data


# check that the hostnames and/or ports are not the same
if [ "${PRIMARY_HOSTNAME}:${PRIMARY_PORT}" = "${STANDBY_HOSTNAME}:${STANDBY_PORT}" ]; then
    logger -s -t $LOGGER_TAG "Aborting failover: servers are the same!"
    exit 1
fi

# ok, we can proceed
logger -s -t $LOGGER_TAG "Automatic failover from ${PRIMARY_HOSTNAME}:${PRIMARY_PORT} to ${STANDBY_HOSTNAME}:${STANDBY_PORT} ..."

logger -s -t $LOGGER_TAG "Issuing a 'promote' action on standby server $STANDBY_HOSTNAME for PGDATA = $STANDBY_PGDATA "
#ssh $STANDBY_HOSTNAME "sudo -u postgres pg_ctl -D $STANDBY_PGDATA promote"
psql -h $STANDBY_HOSTNAME -p $STANDBY_PORT -U postgres --echo-errors  -c 'SELECT pg_promote();' 2> /tmp/promotion.$$.log

if [ $? -ne 0 ]; then
    logger -s -t $LOGGER_TAG "ERROR: cannot promote standby host $STANDBY_HOSTNAME"
    logger -s -t $LOGGER_TAG < /tmp/promotion.$$.log
    exit 1
else
    logger -s -t $LOGGER_TAG "Host $STANDBY_HOSTNAME promoted!"
    exit 0
fi
