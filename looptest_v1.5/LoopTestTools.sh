#!/bin/bash

SHUTDOWN="01.关机测试(S5)"
REBOOT="02.重启测试(reboot)"
SUSPEND="03.待机测试(S3)"
SLEEP="04.休眠测试(S4)"
LOGOUT="05.注销测试(未完成)"

NUM_FILE=/var/tmp/looptime
TOTAL_FILE=/var/tmp/totaltime
TIMESTAMP_FILE=/var/tmp/lasttime
TESTTYPE=/var/tmp/testtype
LOG_FILE=/var/tmp/looptest.log
CANCEL_FILE=/var/tmp/cancel

if [ $UID -ne 0 ];then
	zenity --info --text="该程序每次以ROOT身份执行"
	exit;
fi;

# init files
echo 1 > $NUM_FILE
echo 0 > $TIMESTAMP_FILE

#autoexec file
AUTORUN_FILE=/etc/rc.d/loopsettings.sh
AUTORUN_SERVICE_FILE=/etc/systemd/system/looprun.service
AUTORUN_FLAG=/home/`logname`/.autorunstat

rm -f ${AUTORUN_FILE}
rm -f ${AUTORUN_SERVICE_FILE}
# check systemd system?
if [ `which systemctl` ];then
	echo "systemctl system find, enable looprun.service"
	cat >> ${AUTORUN_SERVICE_FILE}<<Autoexec
[Unit]
Description=CS2C Loop Run Test Service

[Service]
ExecStart=${AUTORUN_FILE}
StandardOutput=syslog
Type=oneshot

[Install]
WantedBy=multi-user.target
Alias=cs2ctest.service
Autoexec
	chmod +x ${AUTORUN_SERVICE_FILE}
	systemctl enable looprun.service
fi


usrname=`logname`
chmod 755 *.sh

echo '#!/bin/bash ' > ${AUTORUN_FILE}
echo "chmod 666 /sys/class/rtc/rtc0/wakealarm " >> ${AUTORUN_FILE}
# autorun file must be run after a GUI user autologin
# scan the screen :0 every 1s by who command
echo 'rlt=1' >> ${AUTORUN_FILE}
echo 'while [ $rlt -ne 0 ]' >> ${AUTORUN_FILE}
echo 'do'  >> ${AUTORUN_FILE}
echo '   if who | grep \(:0\);then'  >> ${AUTORUN_FILE}
echo '       rlt=$?' >> ${AUTORUN_FILE}
echo '   else who | grep \(:1\)' >> ${AUTORUN_FILE}
echo '       rlt=$?' >> ${AUTORUN_FILE}
echo '   fi' >> ${AUTORUN_FILE}
echo '   sleep 1' >> ${AUTORUN_FILE}
echo 'done' >> ${AUTORUN_FILE}
chmod 755 ${AUTORUN_FILE}

BASHRCFILE="/home/$usrname/.bash_profile"
echo "xhost +" >> ${BASHRCFILE}
echo "touch $AUTORUN_FLAG" >> ${BASHRCFILE}

SELECTION=`zenity --list --radiolist --title="中标软件自动化测试工具"  \
	--text="选择测试类型："  --column "" --column "请您选择" \
	True "$SHUTDOWN" Fasle "$REBOOT" Fasle "$SUSPEND" Fasle "$SLEEP" \
	Fasle "$LOGOUT"`
	
if [ -e $SELECTION ] ; then 
    exit 255
fi
if [ "$SELECTION"  =  "$SHUTDOWN"  ] ;then
	sh Shutdown_Loop_setting.sh
	#chmod 666 /etc/gdm/custom.conf;
	TestNo=` zenity  --entry --text="请您输入需要关机测试的次数" `
	if [ -e $TestNo ] ;then 
		exit 1
	fi
	echo $TestNo > $TOTAL_FILE
	chmod 666 $TOTAL_FILE
	# shutdown need run after user login and run "xhost +" for the zenity support
	echo "TIMEOUT=300" >>${AUTORUN_FILE}
	echo "cnt=1" >>${AUTORUN_FILE}
	echo "while [ ! -e $AUTORUN_FLAG ]" >>${AUTORUN_FILE}
	echo "do" >>${AUTORUN_FILE}
	echo "    sleep 1" >>${AUTORUN_FILE}
	echo "    let cnt=\$cnt+1" >>${AUTORUN_FILE}
	echo "    if [ \$cnt -ge \$TIMEOUT  ]" >>${AUTORUN_FILE}
	echo "    then" >>${AUTORUN_FILE}
	echo "        echo '**> [FAIL] Waiting autorun flag file timeout,test abort' > $LOG_FILE" >>${AUTORUN_FILE}
	echo "        echo 'TIMEOUT_WAITFLAGFILE' > $CANCEL_FILE" >>${AUTORUN_FILE}
	echo "        break" >>${AUTORUN_FILE}
	echo "    fi" >>${AUTORUN_FILE}
	echo "done" >>${AUTORUN_FILE}
	# delete the flag file for next loop
	echo "rm -f $AUTORUN_FLAG" >>${AUTORUN_FILE}
	echo "`pwd`/Shutdown_Loop.sh" >>${AUTORUN_FILE}
	sh Shutdown_Loop.sh

elif [ "$SELECTION"  =  "$REBOOT"  ]; then
	sh Warmboot_Loop_setting.sh
	TestNo=` zenity  --entry --text="请您输入需要重启测试的次数" `
	if [ -e $TestNo ] ;then 
		exit 1
	fi
	echo $TestNo > $TOTAL_FILE
	chmod 666 $TOTAL_FILE
	echo "`pwd`/Warmboot_Loop.sh" >>${AUTORUN_FILE};
	sh Warmboot_Loop.sh

elif [ "$SELECTION" = "$SUSPEND"  ] ;then
    sh S3_Suspend_Loop_setting.sh
	TestNo=` zenity  --entry --text="请您输入需要待机测试的次数" `
	if [ -e $TestNo ] ;then 
		exit 1
	fi
	echo $TestNo > $TOTAL_FILE
	chmod 666 $TOTAL_FILE
	sh S3_Suspend_Loop.sh

elif [ "$SELECTION" = "$LOGOUT"  ] ;then
	TestNo=` zenity  --entry --text="请您输入需要注销测试的次数" `
	if [ -e $TestNo ] ;then 
	exit 
	fi
	echo $TestNo > $TOTAL_FILE
	chmod 666 $TOTAL_FILE
	sh Logout_loop.sh

elif [ "$SELECTION" = "$SLEEP"  ] ;then
    sh Sleep_Loop_setting.sh
	TestNo=` zenity  --entry --text="请您输入需要休眠测试的次数" `
	if [ -e $TestNo ] ;then 
	exit 
	fi
	echo $TestNo > $TOTAL_FILE
	chmod 666 $TOTAL_FILE
	sh Sleep_loop.sh
else
	echo "未知选项：$SELECTION"
	exit 1
fi
# disable the looprun.service
if [ `which systemctl` ];then
    systemctl disable looprun.service
fi
