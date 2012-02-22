#!/bin/sh

PGDATA=/postgresql/cluster1
echo "Initializing PostgreSQL cluster in $PGDATA"
echo 'postgresql_enable=”YES”' >> /etc/rc.conf
echo 'postgresql_data=”$PGDATA”' >> /etc/rc.conf
mkdir -p $PGDATA
chown pgsql:pgsql $PGDATA
/usr/local/etc/rc.d/postgresql initdb 