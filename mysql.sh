#!/bin/bash

### Host OS CentOS 7

# Declare variables
MYSQL_NEW_ROOT_PASSWORD='la_3araZa'
MYSQL_RELEASE_FILE="mysql57-community-release-el7-11.noarch.rpm"

#creating variable with twm user pass.
# DB_USERPASS='1a_ZaraZa@'

# VAR_FILE="/etc/profile.d/varapp.sh"

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
#MYSQL_ROOT_PASSWORD_FIELD=$(grep 'temporary password' /var/log/mysqld.log | gawk '{print NF}')
#MYSQL_ROOT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | gawk '{print($MYSQL_ROOT_PASSWORD_FIELD)}')
MYSQL_ROOT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log|cut -d " " -f 11)
mysqladmin --user=root --password="$MYSQL_ROOT_PASSWORD" password "$MYSQL_NEW_ROOT_PASSWORD"
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
	
	# yum install -y expect
	# SECURE_MYSQL=$(expect -c "
	# set timeout 10
	# spawn mysql_secure_installation
	# expect \"Enter password for user root:\"
	# send \"$MYSQL_ROOT_PASSWORD\r\"
	# expect \"New password:\"
	# send \"$MYSQL_NEW_ROOT_PASSWORD\r\"
	# expect \"Re-enter new password:\"
	# send \"$MYSQL_NEW_ROOT_PASSWORD\r\" 
	# expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
	# send \"n\r\"
	# expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
	# send \"y\r\"
	# expect \"Disallow root login remotely?\"
	# send \"y\r\"
	# expect \"Remove test database and access to it?\"
	# send \"y\r\"
	# expect \"Reload privilege tables now?\"
	# send \"y\r\"
	# expect eof
	# ")
	# sudo yum erase -y expect 2>>LOG
else
	mysql -u root -p"$MYSQL_NEW_ROOT_PASSWORD" -e "FLUSH PRIVILEGES"
	echo "MySQL version > 5.6"
fi

firewall-cmd --permanent --zone=public --add-port=3306/tcp 2>>$LOG
echo "$SECURE_MYSQL"


echo "MYSQL_NEW_ROOT_PASSWORD = $MYSQL_NEW_ROOT_PASSWORD">/opt/mysql.txt

echo "Mysql section FINISHED!!"
