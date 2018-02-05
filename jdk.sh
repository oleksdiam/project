#!/bin/bash

#Make sure that trere is already installed wget on your machine
#else uncomment next row 
# sudo yum install -y  wget

#JavaSetup section	#
#####################
#This script downloads and setup Oracle Java 1.8.0.162#
#################################################

JAVA_DOWNLOAD_LINK=http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.rpm
JAVA_PACKAGE=$(echo $JAVA_DOWNLOAD_LINK|cut -d '/' -f 9)
echo "$JAVA_PACKAGE"
#downloading and unpaking
# sudo mkdir /var/log/vagrantLogs
LOG="/var/log/vagrantLogs/javaERR.log"
sudo cd /usr/local/src/ && wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "$JAVA_DOWNLOAD_LINK"
sudo rpm -ihv $JAVA_PACKAGE 2>>$LOG
#creating version independent directory
sudo ln -s /usr/java/jdk1.8.0_162 /usr/jdk 2>>$LOG
export JAVA_HOME=/usr/jdk
export JRE_HOME=/usr/jdk/jre
export PATH=$JAVA_HOME"/bin":$PATH
sudo echo "JAVA_HOME=$JAVA_HOME">>/etc/environment 2>>$LOG
sudo echo "JRE_HOME=$JRE_HOME">>/etc/environment 2>>$LOG
sudo echo "PATH=$PATH:/usr/jdk/bin:/usr/jdk/jre/bin">>/etc/environment 2>>$LOG
sudo rm -f $JAVA_PACKAGE 2>>$LOG
sudo echo "Java DONE!"
#cd ~/
