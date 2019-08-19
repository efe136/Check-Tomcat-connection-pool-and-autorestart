#!/bin/bash
#writen by Alikhan Damirov
#contributed by Efkan Isazade and redesigned for tomcat connection pool and auto restart tomcat

while getopts "h:p:s:w:c:" opt; do
        case $opt in
               # h) host_var="$OPTARG" ;;
                p) port_var="$OPTARG" ;;
                s) state="$OPTARG" ;;
                w) warn_var="$OPTARG"  ;;
                c) crit_var="$OPTARG"  ;;
        esac
done
## take an count of connetins
con_count_var=$(netstat -na | grep $port_var | grep $state | wc -l)

echo Active Connections is: "$con_count_var "

tomcat_pid() {
  echo `ps aux | grep org.apache.catalina.startup.Bootstrap | grep -v grep | awk '{ print $2 }'`
}

pid=$(tomcat_pid)

SHUTDOWN_WAIT=5

#exit codes for icinga
OK=0
WARNING=1
CRITICAL=2
#UNKNOWN=3

#now set the plugin result

if [ "$con_count_var" = "$crit_var" ];
        then
          echo "Status is CRITICAL"
        pid=$(tomcat_pid)
        if [ -n "$pid" ]
        then
          echo "Stoping Tomcat"
          /opt/apache-tomcat-8.5.13/bin/shutdown.sh

        let kwait=$SHUTDOWN_WAIT
        count=0;
        until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
        do
          echo -n -e "\nwaiting for processes to exit";
          sleep 1
        let count=$count+1;
        done

        if [ $count -gt $kwait ]; then
          echo -n -e "\nkilling processes which didn't stop after $SHUTDOWN_WAIT seconds"
          kill -9 $pid
          echo  " \nprocess killed manually"
        fi
        else
          echo "Tomcat is not running"
        fi

        pid=$(tomcat_pid)
        if [ -n "$pid" ]
        then
          echo "Tomcat is already running (pid: $pid)"
        else
        # Start tomcat
          echo "Starting tomcat"
          /opt/apache-tomcat-8.5.13/bin/startup.sh
          echo "Tomcat status (pid: $pid)"
        fi

        exit 0

elif [ "$con_count_var" = "$warn_var" ];
        then
                echo "Status is WARNING" && exit "$WARNING"
else
                echo "Status is OK" && exit "$OK"
fi
