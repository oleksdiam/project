#!/bin/bash

### Host OS CentOS 7

MYSQL_NEW_ROOT_PASSWORD='la_3araZa'
MYSQL_RELEASE_FILE='mysql57-community-release-el7-11.noarch.rpm'
JAVA_DOWNLOAD_LINK=http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.rpm
JAVA_PACKAGE=$(echo $JAVA_DOWNLOAD_LINK|cut -d '/' -f 9)

# Here have to be declare Maven variable
MAVEN_DOWNLOAD_LINK="http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz"


#Define app location at git repo
APP_URI='https://github.com/if-078/TaskManagmentWizard-NakedSpring-.git'

#creating variable with twm user pass.
TMWPASS='1a_ZaraZa@'

#
VAR_FILE="/etc/profile.d/varapp.sh"

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
yum update -y

mkdir /var/log/vagrantLogs
LOG=/var/log/vagrantLogs/baseSetupERR.log

rm -fr /etc/localtime 2>$LOG
ln -s /usr/share/zoneinfo/Europe/Kiev /etc/localtime 2>>LOG
yum install -y ntpdate 2>>$lOG
ntpdate -u pool.ntp.org 2>>$LOG   #command not found
yum install -y wget 2>>$LOG
yum install -y mc 2>>$LOG
yum install -y net-tools.x86_64 2>>$LOG
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

# echo "JAVA_HOME=/usr/jdk" > $VAR_FILE
# echo "JRE_HOME=/usr/jdk/jre" >> $VAR_FILE
echo   "export ${JHOME_VAR}=${JHOME_VALUE}" > $VAR_FILE
echo   "export ${JRE_VAR}=${JRE_VALUE}" >> $VAR_FILE
# echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${JHOME_VAR}) variable"

echo   "export ${MHOME_VAR}=${MHOME_VALUE}" >> $VAR_FILE
# echo "$(drawtext bold 2 "[ OK ]")" --- "Writting $(drawtext bold 2 ${MHOME_VAR}) variable"
echo "export PATH=$PATH:${JHOME_VALUE}/bin:${JRE_VALUE}/bin:${MHOME_VALUE}/bin" >> $VAR_FILE
chmode 754 $VAR_FILE
source $VAR_FILE

# export JAVA_HOME=/usr/jdk
# #export JAVA_HOME=/usr/java/jdk1.8.0_162
# export JRE_HOME=/usr/jdk/jre
# export PATH=$JAVA_HOME"/bin":$PATH

rm -f $JAVA_PACKAGE 2>>$LOG
echo "Java DONE!"

###################################################
#MYsql57 SECTION				  #
###################################################
echo "!MYsql section started!"

LOG=/var/log/vagrantLogs/mysqlERR.log
cd /usr
wget https://dev.mysql.com/get/$MYSQL_RELEASE_FILE 2>>LOG

if [ -e $MYSQL_RELEASE_FILE ]
	then
	rpm -ivh $MYSQL_RELEASE_FILE 2>>LOG
	yum install -y mysql-server 2>>LOG
	rm -f $MYSQL_RELEASE_FILE 2>>LOG
	systemctl start mysqld 2>>LOG

#get mysql root pass from mysqld.log
MYSQL_ROOT_PASSWORD_FIELD=$(grep 'temporary password' /var/log/mysqld.log | gawk '{print NF}')
#MYSQL_ROOT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | gawk '{print($MYSQL_ROOT_PASSWORD_FIELD)}')
MYSQL_ROOT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log|cut -d " " -f 11)
mysqladmin --user=root --password="$MYSQL_ROOT_PASSWORD" password "$MYSQL_NEW_ROOT_PASSWORD"

echo "MYSQL_NEW_ROOT_PASSWORD = $MYSQL_NEW_ROOT_PASSWORD">/opt/mysql.txt
fi


#running secure_installation script for version under 5.7
sqlversion=5.6
sqlversioncurrent=$(mysql --version|awk '{ print $5 }'|awk -F\.21, '{ print $1 }')

if [ "$sqlversioncurrent" = "$sqlversion" ]
	then
	echo "Secure_installation_script automation (for MySQL 5.6 only)"
	mysql -u root -p"$MYSQL_NEW_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
	mysql -u root -p"$MYSQL_NEW_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User=''"
	mysql -u root -p"$MYSQL_NEW_ROOT_PASSWORD" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
	mysql -u root -p"$MYSQL_NEW_ROOT_PASSWORD" -e "FLUSH PRIVILEGES"
else
	mysql -u root -p"$MYSQL_NEW_ROOT_PASSWORD" -e "FLUSH PRIVILEGES"
	echo "MySQL version > 5.6"
fi

# echo "$SECURE_MYSQL"

echo "Mysql section FINISHED!!"

#3. Install Apache-Maven
cd /usr/java
wget "$MAVEN_DOWNLOAD_LINK"
tar -zxvf apache-maven-3.5.2-bin.tar.gz # 2>>${LOG_FILE}
rm -f apache-maven-3.5.2-bin.tar.gz # 2>>${LOG_FILE}
ln -s /usr/java/apache-maven-3.5.2  /usr/maven # 2>>${LOG_FILE}
# mv apache-maven-3.5.2 /usr/java/maven 2>>${LOG_FILE}
mvn -version # 2>>${LOG_FILE}
# echo "MAVEN_HOME=/usr/apache-maven-3.5.2" >> $VAR_FILE
# echo "MAVEN_HOME=/usr/maven" >> $VAR_FILE
source $VAR_FILE
# echo "$(drawtext bold 2 "[ OK ]")" --- ""$(drawtext bold 2 "Apache-Maven")" successfully installed"

LOG="/var/log/vagrantLogs/appERR.log"
echo /dev/null > $LOG

yum install -y git 2>$LOG

# sudo yum install -y git 2>>$LOG
cd /opt
git clone $APP_URI 2>>$LOG

#reading mysql root pass from file
# TP=$(cat /opt/mysql.txt | cut -d " " -f 3)


#creating twm base end user
# mysql -uroot -p$(echo $TP) -e "GRANT ALL ON tmw.* TO 'tmw'@'localhost' IDENTIFIED BY '$TMWPASS';" 2>>$LOG
mysql -uroot -p'$MYSQL_NEW_ROOT_PASSWORD' -e "GRANT ALL ON tmw.* TO 'tmw'@'localhost' IDENTIFIED BY '$TMWPASS';" 2>>$LOG
echo "TMW database end user created"


#change directory to TMW application
cd /opt/T*
cd src/test/resources

#import tmw database
mysql -u tmw -p "$TMWPASS" tmw <create_db.sql 2>>$LOG
mysql -u tmw -p "$TMWPASS" tmw <set_dafault_values.sql 2>>$LOG

cd /opt/T*
MCONF=src/main/resources/mysql_connection.properties
sed -i 's/jdbc.username=root/jdbc.username=tmw/g' $MCONF 2>>$LOG
sed -i 's/jdbc.password=root/jdbc.password='$TMWPASS'/g' $MCONF 2>>$LOG


#add input rules
firewall-cmd --permanent --zone=public --add-port=8585/tcp 2>>$LOG
firewall-cmd --reload 2>>$LOG

##This branch for using iptables
#sudo iptables -I INPUT -p tcp -m tcp --dport 8585 -j ACCEPT
##change iptables settings
#sudo sed -i 's/IPTABLES_SAVE_ON_STOP=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config
#sudo sed -i 's/IPTABLES_SAVE_ON_RESTART=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config

##run application
mvn tomcat7:run-war 2>>$LOG
