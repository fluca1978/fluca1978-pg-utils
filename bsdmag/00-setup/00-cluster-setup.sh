#!/bin/sh

# This script will automate a PostgreSQL cluster initialization.
# The idea is to create the directory, assign permissions and
# force a database cluster initialization.
#
# Please note that this script can destroy all your existing data
# if variables are not correctly set up.



# default variables
PGDATA=/mnt/postgresql/cluster-bsdmag
PG_USER=pgsql

me=`id -u`
PG_USER_ID=`id -u $PG_USER`

if [ ! $me -eq 0 -a ! $me -eq $PG_USER_ID ]
then
    echo "Should run as root for directory creation and permission assignment"
    echo "or as the $PG_USER user (assuming he can create the PGDATA directory)"
    exit 1
fi


# ask the user if he is sure to proceed
answer=""
while [ "$answer" == "" ]
do
    clear
    echo "Will initialize the directory PGDATA = $PGDATA"
    echo "with the user $PG_USER"
    echo "and this WILL DESTROY any existing data"
    echo ""
    echo "Continue (y/n)?"
    read answer

    case $answer in
	y|Y) 
	;;
	n|N)
	    echo "Bye!"
	    exit 0
	    ;;
	*) 
	    echo "Please answer y/n"
	    answer=""
	    sleep 2
	    ;;
    esac
done


echo "Creating PGDATA and setting permissions"
mkdir -p $PGDATA > /dev/null 2>&1
chown $PG_USER:$PG_USER $PGDATA
echo "Initializing the cluster directory (this may take a while)"
/usr/local/etc/rc.d/postgresql oneinitdb 
echo "All done"
echo "To ensure PostgreSQL will start automatically, please"
echo "add the following options to /etc/rc.conf:"
echo "-----------------------"
echo postgresql_enable=\"YES\" 
echo postgresql_data=\"$PGDATA\"
echo "-----------------------"
echo "Also check the pg_hba.conf and postgresql.conf files"
