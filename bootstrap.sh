#!/bin/bash

######################################################
# Copyright 2019 Pham Ngoc Hoai
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Repo: https://github.com/sangramsingha/spring-boot-startup-script
#
######### PARAM ######################################

JAVA_OPT=-Xmx1024m
JARFILE=`ls -1r *.jar 2>/dev/null | head -n 1`
PID_FILE=pid.file
RUNNING=N
PWD=`pwd`
TIMEOUT=30

######### DO NOT MODIFY ########


if [ -f $PID_FILE ]; then
        PID=`cat $PID_FILE`
        if [ ! -z "$PID" ] && kill -0 $PID 2>/dev/null; then
                RUNNING=Y
        fi
fi

start()
{
        if [ $RUNNING == "Y" ]; then
                echo -e "Error:\t\033[31;1mApplication already running\033[0m"
        else
                if [ -z "$JARFILE" ]
                then
                        echo -e "Error:\t\033[31;1mjar file not found\033[0m"
                else
                        nohup java  $JAVA_OPT -Djava.security.egd=file:/dev/./urandom -jar $PWD/$JARFILE >> output.log 2>&1  &
                        echo $! > $PID_FILE
                        echo -e "INFO:\t\033[35;1mApplication $JARFILE starting...\033[0m"
                        
                        regex='Started.*seconds'
                        tail ${PWD}/output.log -n0 -F | while read line; do
                                echo "$line"
                                if [[ $line =~ $regex ]]; then
                                        pkill -9 -P $$ tail
                                fi
                        done
                        echo -e "INFO:\t\033[35;1mServer is started\033[0m"
                fi
        fi
        read -n 1 -s -r -p "Press any key to exit.........."
        echo ""
}

stop()
{
        if [ $RUNNING == "Y" ]; then
        	echo -e "INFO:\t\033[35;1mShutting down application gracefully pid=$PID, waiting $TIMEOUT\033[0m"
        	kill $PID

		    timeout $TIMEOUT tail --pid=$PID -f /dev/null

		    if [ $? -ne 0 ]; then
                echo -e "Error:\t\033[31;1mApplication did not shut down gracefully, killing $PID forcefully\033[0m"
                kill -9 $PID
		    fi

            rm -f $PID_FILE
            echo -e "INFO:\t\033[35;1mApplication stopped\033[0m"

        else
                echo "Application not running"
        fi

        read -n 1 -s -r -p "Press any key to exit..........."
        echo ""
}

restart()
{
        stop
        start
}

case "$1" in

        'start')
                start
                ;;

        'stop')
                stop
                ;;

        'restart')
                restart
                ;;
        
        '--help')
                echo "Usage: $0 {  start | stop | restart  }"
                exit 1
                ;;
        '-h')
                echo "Usage: $0 {  start | stop | restart  }"
                exit 1
                ;;

        '')
                start
                ;;

        *)
                echo "Usage: $0 {  start | stop | restart  }"
                exit 1
                ;;

esac
exit 0

