# Variables for all the scripts.
# Source include this file in the scripts

PGDATA="/mnt/postgresql/cluster-bsdmag"
PG_USER="pgsql"

DB_USERNAME="bsdmag"
DB_NAME="${DB_USERNAME}db"

# An utility function to execute a command via psql.
# An example of invocation:
#
# psql_execute "SELECT * FROM foo"
#
psql_execute(){
    if [ -z "$1" ]
    then 
       echo "Cannot execute without a command!"
       return
    fi

    psql -U $DB_USERNAME -c "$1" $DB_NAME
}

# An utility function to test if the user is the default postgresql user.
# The function aborts the script if the user is not the postgresql one.
ensure_user_is_postgres(){
    me=`id -u`
    if [ $me -ne `id -u $PG_USER` ]
    then
	echo "This script must be run as the user $PG_USER (or the default PostgreSQL user)"
	exit 99
    fi	

}
