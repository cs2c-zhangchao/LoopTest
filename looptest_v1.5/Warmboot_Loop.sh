#!/bin/bash
#This script will automatically reboot the system.

########################################################################################
# The looping script

TESTDEC="重启测试"
# Log file 
LOG_FILE=/var/tmp/restart_loop_message.log

# Looping time file location
NUM_FILE=/var/tmp/looptime
TOTAL_FILE=/var/tmp/totaltime
CANCEL_FILE=/var/tmp/cancel
TIMESTAMP_FILE=/var/tmp/lasttime

# Check the CANCEL_FILe, if it's not exist, continue test,
# else, break test
if [ -e $CANCEL_FILE ];then
	echo "Find cancel file, Warmboot_loop test break." >> $LOG_FILE
	exit 255
fi

#Check the NUM_FILE, if it's not exist, test abort!
if [ ! -e $NUM_FILE ]; then 
    echo "**> [FAIL] missing $NUM_FILE file, test abort!" >> $LOG_FILE
    echo "LOOPTESTTIME_FILE_MISSING" > $CANCEL_FILE
    exit 2
fi

#Check the TOTAL_FILE, if it's not exist, test abort!
if [ ! -e $TOTAL_FILE ]; then 
    echo "**> [FAIL] missing $TOTAL_FILE file, test abort!" >> $LOG_FILE
    echo "TOTALTESTTIME_FILE_MISSING" > $CANCEL_FILE
    exit 2
fi

loop_time=$(cat $NUM_FILE)
test_time=$loop_time
total_time=$(cat $TOTAL_FILE)



if [ $loop_time -le ${total_time} ] ; then
	loop_time=$(($loop_time+1))
    echo $loop_time > $NUM_FILE
	
	lasttime=$(cat ${TIMESTAMP_FILE})
	nowtime=`date +%s`
	echo $nowtime > ${TIMESTAMP_FILE}
	usetime=0
	if [ "$lasttime" != "0" ];then
        usetime=$(($nowtime-$lasttime))
	    echo "==> reboot to boot system usetime ${usetime} s." >>$LOG_FILE
	fi
#	if [ $usetime -gt 900  ];then
#	    echo "**> reboot to boot system timeout, usetime $usetime." >>$LOG_FILE
#	    echo "TIMEOUT" >$CANCEL_FILE ;
#	    exit 5
#	fi
	
    #record the boot log and boot time
	echo "#######################################################################" >> $LOG_FILE
	echo $loop_time" times" >> $LOG_FILE
	date >> $LOG_FILE
    echo "--------------------dmesg info Begin----------------------" >> $LOG_FILE
	dmesg >> $LOG_FILE
    echo "---------------------dmesg info End-----------------------" >> $LOG_FILE
    echo "The system will reboot after 60 second."
    
    Timeout=60
    for ((i=0;i<=100;));do 
        let Timeout=$Timeout-3
        let i=$i+5 
        echo $i
        echo "#总共${TESTDEC}${total_time}次,当前第${test_time}次.$Timeout秒后${TESTDEC}."
        sleep 3
    done | zenity  --display=:0 --progress  --auto-close 
#    if [ $? -ne 0 ]; 
#    then 
#        echo "USER_ABORT $?" > $CANCEL_FILE ; 
#        zenity --display=:0 --info --text="您取消了${TESTDEC}"
#        exit 255
#    fi
    #reboot the OS
	reboot -f
elif [ ! who | head -n1 | grep  \(:0\) ] && [ $loop_time -ge ${total_time} ];then
	reboot -f

else
    echo "==> [PASS] Warmboot(Reboot) test finished($total_time)." >>$LOG_FILE
    echo "PASSED" >$CANCEL_FILE ;
    #Copy the test log and the rest looptime to home folder.
	cp -f /var/tmp/looptime ~/looptime
	rm -f /var/tmp/looptime
	cp -f /var/tmp/restart_loop_message.log ~/restart_loop_message.log
    zenity --display=:0 --info --text="${TESTDEC}（${total_time}）测试完成！"
	exit 0
fi
