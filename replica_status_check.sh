#!/bin/bash

# Set variables
MAILLIST='<add mails distribution list here>'

# set the email notification threshold for replica delay - 15mins
DELAY_THRESHOLD=900

# get the current replica status
REPLICA_STATUS=$(mysql -e "SHOW REPLICA STATUS\G")

# check if the replica is running
if [[ "$REPLICA_STATUS" == *"Slave_IO_Running: No"* || "$REPLICA_STATUS" == *"Slave_SQL_Running: No"* ]]; then
  # send an email notification if the replica is down
  echo "MySQL replica is down." | mail -s "[Critical] MySQL Replica Alert" $MAILLIST
else
  # get the current delay between primary and replica
  DELAY=$(echo "$REPLICA_STATUS" | grep "Seconds_Behind_Source" | awk '{print $2}')
  
  # check if the delay exceeds the threshold
  if [ $DELAY -gt $DELAY_THRESHOLD ]; then
    # send an email notification if the replica is behind the primary by more than 30 minutes
    echo "MySQL replica is behind primary by more than 30 minutes: $DELAY seconds." | mail -s "[Critical] MySQL Replica Alert" $MAILLIST
  fi
fi
