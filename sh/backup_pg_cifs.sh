#!/bin/sh

SMB_USER=
SMB_SHARE=
SMB_MACHINE=
SMB_IP=
SMB_PASSWORD=

PG_USER=
PG_DATABASE=



MOUNT_POINT=/mnt/$SHARE

# check to see if the share has been already mounted
if [ ! $( mount | grep $SMB_SHARE ) ];
then
    logger "Mounting share $SMBSHARE on $MOUNT_POINT"
    mount -t cifs //${SMB_MACHINE}/${SMB_SHARE} $MOUNTPOINT -o username=$SMB_USER, password=$SMB_PASSWORD,ip=$SMB_IP
    if [ $? -ne 0 ];
    then
        logger "Cannot mount $SMB_SHARE over $MOUNT_POINT, aborting"
        echo   "Cannot mount $SMB_SHARE over $MOUNT_POINT, aborting"
        exit 1
    fi
else
    logger "Share $SMB_SHARE already mounted over $MOUNT_POINT"
fi


sleep 3
BACKUP_DIR=$MOUNT_POINT/$PG_DATABASE/$(date +'day-%w')
logger "Starting backup of database $PG_DATABASE into $BACKUP_DIR"
if [ -d $BACKUP_DIR ];
then
    # remove previous content of this directory
    rm -rf $BACKUP_DIR
fi

# ensure the directory is there
mkdir -p $BACKUP_DIR || exit 

# perform the backup
logger "Backup starting at " $(date)
pg_dump -Fd -f $BACKUP_DIR -U $PG_USER $PG_DATABASE
logger "Backup ended with code [$?] at " $(date)

# umount the folder
sleep 5
umount  $MOUNT_POINT





