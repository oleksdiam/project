#!/bin/bash

### Host OS CentOS 7

MYSQL_RELEASE_FILE='mysql57-community-release-el7-11.noarch.rpm'
JAVA_DOWNLOAD_LINK=http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.rpm
JAVA_PACKAGE=$(echo $JAVA_DOWNLOAD_LINK|cut -d '/' -f 9)

# Here have to be declare Tomcat variable
TOMCAT_DOWNLOAD_LINK="http://apache.volia.net/tomcat/tomcat-7/v7.0.84/bin/apache-tomcat-7.0.84.tar.gz"
TOMCAT_ARCH=apache-tomcat-7.0.84.tar.gz

# Here have to be declare Maven variable
MAVEN_DOWNLOAD_LINK="http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz"


#Define app location at git repo
APP_URI='https://github.com/IF-066-Java/bugTrckr.git'

#creating variable with twm user pass.

#
VAR_FILE="/etc/profile.d/varapp.sh"
echo '#!/bin/bash' > $VAR_FILE

# function drawtext() {
# 	tput $1
# 	tput setaf $2
# 	echo -n $3
# 	tput sgr0
# }

#<------------------ Create System Environment Variables ------------------>
# JAVA
JHOME_VAR="JAVA_HOME"
# JHOME_VALUE="/usr/java/jdk1.8.0_162"
JHOME_VALUE="/usr/jdk"
JRE_VAR="JRE_HOME"
# JRE_VALUE="/usr/java/jdk1.8.0_162/jre"
JRE_VALUE="/usr/jdk/jre"

# MAVEN
MHOME_VAR="MAVEN_HOME"
MHOME_VALUE="/usr/maven"


# Make sure we run script with root privileges
 if [ $UID != 0 ];
 	then
 # not root, use sudo
 # $0=./script.sh
 # $*=treat everything as one word
 # exit $?=return in bash
 	echo "This script needs root privileges, rerunning it now using sudo!"
 	sudo "${SHELL}" "$0" $*
 	exit $?
 fi
 # get real username
 if [ $UID = 0 ] && [ ! -z "$SUDO_USER" ];
 	then
 	USER="$SUDO_USER"
 else
 	USER="$(whoami)"
fi

#basic setup
echo "Updating system...Please wait 5-10 minutes."
mkdir /var/log/vagrantLogs
LOG=/var/log/vagrantLogs/baseSetupERR.log

yum update -y
yum install -y wget 2>>$LOG
yum install -y mc 2>>$LOG
yum install -y net-tools.x86_64
yum install -y git 2>$LOG


rm -fr /etc/localtime 2>$LOG
ln -s /usr/share/zoneinfo/Europe/Kiev /etc/localtime 2>>LOG
yum install -y ntpdate 2>>$lOG
ntpdate -u pool.ntp.org 2>>$LOG   #command not found
#sudo yum install -y git 2>>$LOG 

#JavaSetup section	#
#####################
#This script downloads and setup Oracle Java 1.8.0.162#
#################################################

#downloading and unpaking
# sudo mkdir /var/log/vagrantLogs
LOG="/var/log/vagrantLogs/javaERR.log"
cd /usr/local/src/ && wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "$JAVA_DOWNLOAD_LINK"
rpm -ihv $JAVA_PACKAGE 2>>$LOG
#creating version independent directory
ln -s /usr/java/jdk1.8.0_162 /usr/jdk 2>>$LOG

echo   "export ${JHOME_VAR}=${JHOME_VALUE}" > $VAR_FILE
echo   "export ${JRE_VAR}=${JRE_VALUE}" >> $VAR_FILE
# echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${JHOME_VAR}) variable"

echo   "export ${MHOME_VAR}=${MHOME_VALUE}" >> $VAR_FILE

rm -f $JAVA_PACKAGE 2>>$LOG
echo "Java DONE!"

#APACHE TOMCAT INSTALL SECTioN
cd /usr
wget "$TOMCAT_DOWNLOAD_LINK"
tar -zxvf $TOMCAT_ARCH
rm -f $TOMCAT_ARCH

#3. Install Apache-Maven
cd /usr/java
wget "$MAVEN_DOWNLOAD_LINK"
tar -zxvf apache-maven-3.5.2-bin.tar.gz # 2>>${LOG_FILE}
rm -f apache-maven-3.5.2-bin.tar.gz # 2>>${LOG_FILE}
ln -s /usr/java/apache-maven-3.5.2  /usr/maven # 2>>${LOG_FILE}
# mv apache-maven-3.5.2 /usr/java/maven 2>>${LOG_FILE}
#mvn -version # 2>>${LOG_FILE}
echo   "export CATALINA_HOME=/etc/tomcat" >> $VAR_FILE

# echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${MHOME_VAR}) variable"
echo "export PATH=$PATH:${JHOME_VALUE}/bin:${JRE_VALUE}/bin:${MHOME_VALUE}/bin" >> $VAR_FILE
chmod 754 $VAR_FILE
source $VAR_FILE
# echo "MAVEN_HOME=/usr/apache-maven-3.5.2" >> $VAR_FILE
# echo "MAVEN_HOME=/usr/maven" >> $VAR_FILE
source $VAR_FILE
# echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "Apache-Maven")" successfully installed"

LOG="/var/log/vagrantLogs/appERR.log"
echo /dev/null > $LOG


# sudo yum install -y git 2>>$LOG
cd /opt
git clone $APP_URI 2>>$LOG


#add input rules
firewall-cmd --permanent --zone=public --add-port=8585/tcp 2>>$LOG
firewall-cmd --reload 2>>$LOG

##This branch for using iptables
#sudo iptables -I INPUT -p tcp -m tcp --dport 8585 -j ACCEPT
##change iptables settings
#sudo sed -i 's/IPTABLES_SAVE_ON_STOP=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config
#sudo sed -i 's/IPTABLES_SAVE_ON_RESTART=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config

##run application
# mvn tomcat7:run-war 2>>$LOG
