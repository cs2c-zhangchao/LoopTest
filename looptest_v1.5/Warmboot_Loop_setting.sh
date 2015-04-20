#!/bin/bash
#This script is to prepare the test environment for loop test.

# time stamp
TIMESTAMP_FILE=/var/tmp/lasttime

#get login user to do loop test
looptestuser=`logname`

#Backup and clear the /var/tmp folder.
cp -rf /var/tmp/ /var/tmpbackup/
rm -f /var/tmp/cancel
#rm -f /var/tmp/lasttime
rm -f /var/tmp/*.log


echo 0 > ${TIMESTAMP_FILE}

#Change gnome custom config file to enable autologin.
chmod 777 /etc/gdm/custom.conf

mv -f /etc/gdm/custom.conf /etc/gdm/custom.conf.old

cat >> /etc/gdm/custom.conf << Autologin
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$looptestuser

Autologin

#Reboot the system after 1min.
#echo "System will be restarted after 60 seconds,please save your data first."
#sleep 60
#reboot

