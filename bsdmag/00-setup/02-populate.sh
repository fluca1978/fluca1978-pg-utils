#!/bin/sh

# load variables
. ../bsdmag-config.sh
POPULATE_FILE=magazine.sql

echo "Populating the database using the file $POPULATE_FILE"
psql -U $DB_USERNAME -f $POPULATE_FILE $DB_NAME

