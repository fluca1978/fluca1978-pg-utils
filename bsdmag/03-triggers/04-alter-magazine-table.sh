#!/bin/sh

echo "Adding the availability column to the magazine table"
psql -U bsdmag -c "ALTER TABLE magazine ADD COLUMN available boolean DEFAULT true;" bsdmagdb
echo "Making all entries available"
psql -U bsdmag -c "UPDATE magazine SET available = true;" bsdmagdb