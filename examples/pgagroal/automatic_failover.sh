#!/bin/sh

#
# This is an example script for pgagroal failover.
# See <https://github.com/agroal/pgagroal/blob/maser/doc/FAILOVER.md>
#
# The script receives four parameters:
# $1 = the hostname of the primary (failing) server
# $2 = the port of the primary (failing) server
# $3 = the hostname of the PostgreSQL instance to promote
# $4 = the port of the PostgreSQL instance to promote
#
# The script executes a `pgsql` to the PostgreSQL instance to promote, then
# issueing the `pg_promote()` command.
# It is required that the `postgres` user can connect to the server to promote
# without the need for a password, hence using .pgpass to the aim.
#
# This script has to return 0 as exit code in order to signal to pgagroal
# that the promotion has been successful.
#
# To configure pgagroal:
# failover = on
# failover_script = /path/to/automatic_failover.sh
#


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



# check that the hostnames and/or ports are not the same
if [ "${PRIMARY_HOSTNAME}:${PRIMARY_PORT}" = "${STANDBY_HOSTNAME}:${STANDBY_PORT}" ]; then
    logger -s -t $LOGGER_TAG "Aborting failover: servers are the same!"
    exit 1
fi

# ok, we can proceed
logger -s -t $LOGGER_TAG "Automatic failover from ${PRIMARY_HOSTNAME}:${PRIMARY_PORT} to ${STANDBY_HOSTNAME}:${STANDBY_PORT} ..."

logger -s -t $LOGGER_TAG "Issuing a 'promote' action on standby server $STANDBY_HOSTNAME"

psql -h $STANDBY_HOSTNAME -p $STANDBY_PORT -U postgres --echo-errors  -c 'SELECT pg_promote();' 2> /tmp/promotion.$$.log

if [ $? -ne 0 ]; then
    logger -s -t $LOGGER_TAG "ERROR: cannot promote standby host $STANDBY_HOSTNAME"
    logger -s -t $LOGGER_TAG < /tmp/promotion.$$.log
    exit 1
else
    logger -s -t $LOGGER_TAG "Host $STANDBY_HOSTNAME promoted!"
    exit 0
fi
