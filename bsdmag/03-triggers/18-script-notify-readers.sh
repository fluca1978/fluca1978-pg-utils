#!/bin/sh

psql -U bsdmag -c "SET client_min_messages TO LOG; SELECT notify_readers_new_issue(); " bsdmagdb