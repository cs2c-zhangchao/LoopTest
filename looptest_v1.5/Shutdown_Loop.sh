#!/bin/bash
#This script will automatically Shutdown and Re-boot the system by RTC.

########################################################################################
# The looping script
TESTDEC="关机测试"
# Log file 
LOG_FILE=/var/tmp/Shutdown_loop_message.log

# Looping time file location
NUM_FILE=/var/tmp/looptime
TOTAL_FILE=/var/tmp/totaltime
CANCEL_FILE=/var/tmp/cancel
TIMESTAMP_FILE=/var/tmp/lasttime
LOG_PATH=/var/tmp

# waiting time for every loop test.
Timeout=60 
WakeupTime=120 # include the shutdown time for OS

# Check the CANCEL_FILe, if it's not exist, continue test,
# else, break test
if [ -e $CANCEL_FILE ];then
    echo "**> Find cancel file, Shutdown_loop test break." >> $LOG_FILE
    exit 255
fi

#Check the NUM_FILE, if it's not exist, test abort!
if [ ! -e $NUM_FILE ]; then 
    echo "**> [FAIL] missing $NUM_FILE file, test abort!" >> $LOG_FILE
    echo "LOOPTIME_FILE_MISSING" > $CANCEL_FILE
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
    #test_time=$(($total_time-$loop_time))
    echo $loop_time > $NUM_FILE
    lasttime=$(cat ${TIMESTAMP_FILE})
    nowtime=`date +%s`
    echo $nowtime > ${TIMESTAMP_FILE}
	usetime=0
	if [ "$lasttime" != "0" ];then
        usetime=$(($nowtime-$lasttime))
	    echo "==> reboot to boot system usetime ${usetime} s." >>$LOG_FILE
	fi
    if [ $usetime -gt 900  ];then
        echo "**> [FAIL] Shutdown to boot system timeout, usetime $usetime." >>$LOG_FILE
        echo "TIMEOUT" >$CANCEL_FILE ;
        exit 5
    fi
    
    #record the boot log and boot time
    echo "#######################################################################" >> $LOG_FILE
    echo $test_time" times" >> $LOG_FILE
    date >> $LOG_FILE
    dmesg >> $LOG_PATH/dmesg_$test_time

    echo "--------------------RTC OLD ${test_time}----------------------" >> $LOG_FILE
    cat /proc/driver/rtc >>$LOG_FILE
    
    echo "The system will poweroff after $Timeout second."


    for ((i=0;i<=100;));do 
        let Timeout=$Timeout-3
        let i=$i+5 
        echo $i
        echo "#总共${TESTDEC}${total_time}次,当前第${test_time}次.$Timeout秒后${TESTDEC}."
        sleep 3
    done | zenity  --display=:0 --progress  --auto-close 
    if [ $? -ne 0 ]; 
    then 
        echo "USER_ABORT $?" > $CANCEL_FILE ; 
        zenity --display=:0 --info --text="您取消了${TESTDEC}"
        exit 255
    fi
    
    #sleep ${Timeout}
    echo 0 > /sys/class/rtc/rtc0/wakealarm
    sleep 1
    echo "+$WakeupTime" > /sys/class/rtc/rtc0/wakealarm
    rlt=$?
    if [ "x$rlt" != "x0" ];then
        echo "**> echo +$WakeupTime to wakalarm file fail($rlt), try sh -c..." >>$LOG_FILE
        date +%s -d "+$WakeupTime seconds" > /sys/class/rtc/rtc0/wakealarm
        if [ "x$?" != "x0" ];then
            echo "**> [FAIL] Shutdown to boot system setting rtc fail,test abort." >>$LOG_FILE
            echo "SET_RTC_FAIL" > $CANCEL_FILE 
            exit 1
        fi
    fi
    echo "--------------------RTC NEW ${test_time}----------------------" >> $LOG_FILE
    cat /proc/driver/rtc >>$LOG_FILE

    #poweroff the OS
    poweroff
else
    echo "#######################################################################" >> $LOG_FILE
    echo "--------------------RTC OLD ${test_time}----------------------" >> $LOG_FILE
    cat /proc/driver/rtc >>$LOG_FILE
    echo "==> [PASS] Shutdown to boot system test finished($total_time)." >>$LOG_FILE
    echo "PASSED" >$CANCEL_FILE ;
    #Copy the test log and the rest looptime to Desktop.
    cp -f /var/tmp/looptime /home/`logname`/looptime
    rm -f /var/tmp/looptime
    cp -f /var/tmp/Shutdown_loop_message.log /home/`logname`/Shutdown_loop_message_passed.log
    cp -f /var/tmp/dmesg_* /home/`logname`/
    zenity --display=:0 --info --text="${TESTDEC}（${total_time}）测试完成！"
    exit 0
fi
