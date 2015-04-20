#!/bin/bash
#This script is to prepare the test environment for loop test.

#get login user to do loop test
looptest=`logname`

#Backup and clear the /var/tmp folder.
cp -rf /var/tmp/ /var/tmpbackup/
rm -f /var/tmp/cancel
rm -f /var/tmp/*.log

#Change gnome custom config file to enable autologin.
chmod 777 /etc/gdm/custom.conf
chmod 666 /sys/class/rtc/rtc0/wakealarm

mv -f /etc/gdm/custom.conf /etc/gdm/custom.conf.old

cat >> /etc/gdm/custom.conf << Autologin
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$looptest
Autologin

#Reboot the system after 1min.
#echo "System will be restarted after 60 seconds,please save your data first."
#sleep 60
#reboot

