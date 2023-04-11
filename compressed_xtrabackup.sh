#!/bin/bash

# This script will creates compressed backup, each sunday it triggers full backups and increment backups rest of the day

# set the MySQL credentials and variables
WORKDIR="/var/lib/mysql/scripts"
XTRABACKUP_PATH="/opt/percona/percona-xtrabackup-8.0.29-22-Linux-x86_64.glibc2.17/bin/" # Replace with your path
XTRABACKUP_USER=backup # Replace with your username
XTRABACKUP_PWD=`cat "$WORKDIR"/".xtrabackup_pwd"` # To store password
SOCKET="/tmp/mysql.sock" 
CONFIGFILE="/etc/my.cnf"

# set the backup directory and file names
BACKUP_DIR=/backups/xtrabackup
FULL_BACKUP_NAME=$BACKUP_DIR/full/full_$(date +%F).xbkp
INC_BACKUP_NAME=$BACKUP_DIR/inc/inc_$(date +%F_%H-%M-%S).xbkp

# set the email address to receive backup status notifications
EMAIL_ADDRESS='' # Add your email address

# check if today is Sunday
if [ "$(date +%u)" -eq 7 ]; then
  # take a full backup on Sunday
  $XTRABACKUP_PATH/xtrabackup --defaults-file=$CONFIGFILE --backup --compress --compress-threads=2 --parallel=4 --user=$XTRABACKUP_USER --password=$XTRABACKUP_PWD --socket=$SOCKET --target-dir=$FULL_BACKUP_NAME

  # send an email notification about the backup status
  if [ $? -ne 0 ]; then
    echo "MySQL backup failed on $(date +%F_%H-%M-%S). Please check and investigate" | mail -s "[Critical] MySQL Full Backup Failed" $EMAIL_ADDRESS
  fi
else
  # take an incremental backup on all other days
  LATEST_FULL_BACKUP=$(ls -d $BACKUP_DIR/full/full_* | sort -nr | head -n 1)
  $XTRABACKUP_PATH/xtrabackup --defaults-file=$CONFIGFILE --backup --compress --compress-threads=2 --parallel=4 --user=$XTRABACKUP_USER --password=$XTRABACKUP_PWD --socket=$SOCKET --target-dir=$INC_BACKUP_NAME --incremental-basedir=$LATEST_FULL_BACKUP
  # send an email notification about the backup status
  if [ $? -ne 0 ]; then
    echo "MySQL backup failed on $(date +%F_%H-%M-%S). Please check and investigate" | mail -s "[Critical] MySQL Inc Backup Failed" $EMAIL_ADDRESS
  fi
fi

# delete backups older than 2 weeks
find $BACKUP_DIR -type f -name "*.xbkp" -mtime +14 -delete
