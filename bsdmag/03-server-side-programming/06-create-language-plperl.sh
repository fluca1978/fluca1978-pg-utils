#!/bin/sh

psql -U bsdmag -c "CREATE OR REPLACE LANGUAGE plperl;" bsdmagdb