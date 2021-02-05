#!/bin/sh

# This is an example skeleton script to be used with Barman.
# The script simply dumps the BARMAN_xxx variables on a log file
# in order to demonstrate when and how diferent branches are invoked
# depending on the kind of configuration.
# To test this script in your setup:
#
# pre_backup_script = /usr/local/bin/barman_script.sh
# post_backup_script = /usr/local/bin/barman_script.sh
# pre_delete_script  = /usr/local/bin/barman_script.sh
# post_delete_script = /usr/local/bin/barman_script.sh
# pre_archive_script = /usr/local/bin/barman_script.sh
# post_archive_script = /usr/local/bin/barman_script.sh
# pre_wal_delete_script = /usr/local/bin/barman_script.sh
# post_wal_delete_script = /usr/local/bin/barman_script.sh

# Example output for a backup command:
#
# % barman backup miguel
# ======================================
# /usr/local/bin/barman_script.sh working for server [miguel]
# this is a pre hook script
# this is a run-once script, exit status ignored
# Working for the backup [20190911T111404] (prev was [20190911T102239], next is []
# Backup dir is [/backup/barman/miguel/base/20190911T111404]
# ======================================
# ======================================
# /usr/local/bin/barman_script.sh working for server [miguel]
# this is a post hook script
# there are not know errors
# this is a run-once script, exit status ignored
# Working for the backup [20190911T111404] (prev was [20190911T102239], next is []
# Backup dir is [/backup/barman/miguel/base/20190911T111404]
# ======================================
#
# Example output when working on a WAL segment (e.g., barman cron)
#
#
# ======================================
# /usr/local/bin/barman_script.sh working for server [miguel]
# this is a pre hook script
# this is a run-once script, exit status ignored
# Working on WAL segment [00000005000002130000007D] which is on file [/backup/barman/miguel/incoming/00000005000002130000007D] of size [16777216]
# Segment [00000005000002130000007D] created on [1568194218.94] with compression []
# ======================================



LOG_FILE=/tmp/$0.log


if [ -z "$BARMAN_SERVER" ]; then
    echo "This script must be run in a barman context!"
    exit 1
fi

echo "======================================" | tee -a $LOG_FILE
echo "$0 working for server [$BARMAN_SERVER]" | tee -a $LOG_FILE
if [ "$BARMAN_PHASE" = "pre" ]; then
    echo "this is a pre hook script" | tee -a $LOG_FILE
else
    echo "this is a post hook script" | tee -a $LOG_FILE
    if [ -z "$BARMAN_ERROR" ]; then
        echo "there are not know errors" | tee -a $LOG_FILE
    else
        echo "error [$BARMAN_ERROR]" | tee -a $LOG_FILE
    fi
fi


if [ "$BARMAN_RETRY" -eq 1 ]; then
    echo "this is retry script [$BARMAN_RETRY], mind your exit status!" | tee -a $LOG_FILE
else
    echo "this is a run-once script, exit status ignored" | tee -a $LOG_FILE
fi

if [ ! -z "$BARMAN_BACKUP_ID" ]; then
    echo "Working for the backup [$BARMAN_BACKUP_ID] (prev was [$BARMAN_PREVIOUS_ID], next is [$BARMAN_NEXT_ID]" | tee -a $LOG_FILE
    echo "Backup0 dir is [$BARMAN_BACKUP_DIR]" | tee -a $LOG_FILE
fi


if [ ! -z "$BARMAN_SEGMENT" ]; then
    echo "Working on WAL segment [$BARMAN_SEGMENT] which is on file [$BARMAN_FILE] of size [$BARMAN_SIZE]" | tee -a $LOG_FILE
    echo "Segment [$BARMAN_SEGMENT] created on [$BARMAN_TIMESTAMP] with compression [$BARMAN_COMPRESSION]" | tee -a $LOG_FILE
fi

if [ ! -z "$BARMAN_REMOTE_COMMAND" ]; then
    echo "Doing a recovery thru command [$BARMAN_REMOTE_COMMAND] on directory [$BARMAN_DESTINATION_DIRECTORY]" | tee -a $LOG_FILE
fi


echo "======================================" | tee -a $LOG_FILE
exit 0
