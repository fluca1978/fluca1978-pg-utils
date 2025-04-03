#!/bin/sh

# start pgagroal
/usr/bin/pgagroal -d


# do a initial pgbadger run so the user has not to wait
# five minutes for the first update
/usr/bin/pgbadger -I -f stderr -O /data/html /postgres/17/data/log/*.log > /dev/null 2>&1
