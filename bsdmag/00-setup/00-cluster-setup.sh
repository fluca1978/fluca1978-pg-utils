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
    cat <<EOF
Should run as root for directory creation and permission assignment
or as the $PG_USER user (assuming he can create the PGDATA directory).
EOF
fi


# ask the user if he is sure to proceed
answer=""
while [ "$answer" == "" ]
do
    clear
cat <<EOF
Will initialize the directory PGDATA = $PGDATA
with the user $PG_USER
and this WILL DESTROY any existing data!!!!!!
Continue (y/n)?
EOF
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


if [ ! -d $PGDATA ]
then
    echo "Creating PGDATA and setting permissions"
    mkdir -p $PGDATA > /dev/null 2>&1
    
else
    echo "Cleaning up $PGDATA (destroying data!)"
    rm -rf $PGDATA/*
fi
echo "Fixing directory permissions"
chown $PG_USER:$PG_USER $PGDATA
echo "Initializing the cluster directory (this may take a while)"

# It is important to export the rc variable used in the script, or
# it will use the default value /usr/local/pgsql/data !!!!
postgresql_data="$PGDATA"
export postgresql_data
/usr/local/etc/rc.d/postgresql  oneinitdb 
echo "All done"
cat <<EOF
To ensure PostgreSQL will start automatically, please
add the following options to /etc/rc.conf:

#### PostgreSQL Configuration ####
postgresql_enable="YES"
postgresql_data="$PGDATA"
##################################

and also review settings in files
$PGDATA/{ pg_hba.conf, postgresql.conf }

EOF

