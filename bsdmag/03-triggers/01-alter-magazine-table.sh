#!/bin/sh

echo "Adding the download_path column to the magazine table"
psql -U bsdmag -c "ALTER TABLE magazine ADD COLUMN download_path text;" bsdmagdb