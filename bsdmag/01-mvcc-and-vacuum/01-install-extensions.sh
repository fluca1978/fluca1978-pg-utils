#!/bin/sh

echo "Installing extensions into the database..."
for extension in pageinspect pgstattuple
do
    echo "$extension"
    psql -U bsdmag -c "CREATE EXTENSION $extension;" bsdmagdb
    echo "done ($?)"
done
