#!/bin/bash
#This script will automatically suspend and resume the system.

########################################################################################
# The looping script

TESTDEC="待机测试"
# Log file 
LOG_FILE=/var/tmp/S3_Suspend_message.log

NUM_FILE=/var/tmp/looptime
TOTAL_FILE=/var/tmp/totaltime
CANCEL_FILE=/var/tmp/cancel
TIMESTAMP_FILE=/var/tmp/lasttime


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

echo "The log file S3_Suspend_message.log is created in /var/tmp folder."
testtime=`cat $TOTAL_FILE`

for((loop=1;loop<=$testtime;loop++))
do    
#record the suspend and resume log
    echo "#######################################################################" >> $LOG_FILE
    echo $loop" times" >> $LOG_FILE
    date >> $LOG_FILE
    echo "--------------------dmesg info Begin----------------------" >> $LOG_FILE
    dmesg >> $LOG_FILE
    echo "---------------------dmesg info End-----------------------" >> $LOG_FILE
    echo "The system will suspend after 30 second and resume after 60 second when it's in S3($loop/$testtime)."
    
    Timeout=60    
    for ((i=0;i<=100;));do 
        let Timeout=$Timeout-3
        let i=$i+5 
        echo $i
        echo "#总共${TESTDEC}${testtime}次,当前第${loop}次.$Timeout秒后${TESTDEC}."
        sleep 3
    done | zenity  --display=:0 --progress  --auto-close 
    if [ $? -ne 0 ]; 
    then 
        echo "USER_ABORT $?" > $CANCEL_FILE ; 
        zenity --display=:0 --info --text="您取消了${TESTDEC}"
        exit 255
    fi
    #sleep 30
    rtcwake --mode=mem --second=60
done
echo "==> [PASS] Suspend(S3) and resume test finished($testtime)." >>$LOG_FILE
echo "PASSED" >$CANCEL_FILE ;
#Change mod of log file
chmod 777 $LOG_FILE
echo "Please check the log file in /var/tmp folder."
zenity --display=:0 --info --text="${TESTDEC}（${testtime}）测试完成！"
exit 0
