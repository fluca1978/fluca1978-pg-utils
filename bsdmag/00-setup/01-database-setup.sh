#!/bin/sh

echo "Creating user bsdmag, please provide a password"
createuser -P bsdmag
echo "Creating database bsdmagdb"
createdb -O bsdmag bsdmagdb