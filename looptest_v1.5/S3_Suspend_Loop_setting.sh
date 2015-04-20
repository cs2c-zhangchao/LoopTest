#!/bin/bash
# This script is to prepare the test environment for loop test.

# time stamp
TIMESTAMP_FILE=/var/tmp/lasttime

# get login user to do loop test
looptest=`logname`

# Backup and clear the /var/tmp folder.
cp -rf /var/tmp/ /var/tmpbackup/
rm -f /var/tmp/cancel
rm -f /var/tmp/*.log

# echo 0 to time stamp file
echo 0 > ${TIMESTAMP_FILE}


