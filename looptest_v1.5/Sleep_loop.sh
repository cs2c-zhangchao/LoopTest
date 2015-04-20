#!/bin/bash
#This script will automatically sleep and resume the system.

########################################################################################
# The looping script

TESTDEC="休眠测试"
# Log file 
LOG_FILE=/var/tmp/S4_Sleep_message.log

NUM_FILE=/var/tmp/looptime
TOTAL_FILE=/var/tmp/totaltime

echo "The log file S4_Sleep_message.log is created in /var/tmp folder."
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
    echo "The system will sleep after 30 second and resume after 60 second when it's in S4.($loop/$testtime)" 
       
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
    rtcwake --mode=disk --second=60

done
echo "==> [PASS] Sleep(S4) test finished($testtime)." >>$LOG_FILE
echo "PASSED" >$CANCEL_FILE ;
#Change mod of log file
chmod 777 $LOG_FILE
echo "Please check the log file in /var/tmp folder."
zenity --display=:0 --info --text="${TESTDEC}（${testtime}）测试完成！"
exit 0
