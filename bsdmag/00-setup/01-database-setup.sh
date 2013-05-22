#!/bin/sh

# This script will create a demo user and database on
# a running (locally) PostgreSQL cluster.

# load config variables
. ../bsdmag-config.sh
DB_CONNECTION_LIMIT=2

# check if the user is the postgresql one and exit if not
ensure_user_is_postgres



cat <<EOF
Will create the database $DB_NAME and user/owner $DB_USERNAME
with a connection limit of $DB_CONNECTION_LIMIT concurrent sessions.
Please note that the user will be limited (no superuser, no create database, etc.).
-----------------------------------------------------
EOF

# -c => connection limit
# -e => echo createuser SQL command
# -E => encrypt password
# -l => allow user to log in
# -S => user is not a superuser
# -D => user is not able to create new database
# -P => prompt for a password
createuser -c ${DB_CONNECTION_LIMIT} -e -E -l -S -D -P ${DB_USERNAME}
createdb -e -O ${DB_USERNAME} ${DB_NAME}

cat <<EOF
---------------------------------------------------
In order to ease the connection to the database, 
ensure you have a file named $HOME/.pgpass 
with the following content:

localhost:5432:${DB_NAME}:${DB_USERNAME}:<your-password>

and with the permissions 0600.

To connect to the database from a command line just
type the following command:

psql -U $DB_USERNAME $DB_NAME
---------------------------------------------------
EOF
