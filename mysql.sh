#!/bin/bash

#SYNOPSYS   mysql_secure.sh <MySQL_new_root_password>

MYSQL_NEW_ROOT_PASSWORD='la_3araZa'
###################################################
#MYsql57 SECTION				  #
###################################################
echo "!MYsql section started!"

sudo yum install -y expect

LOG=/var/log/vagrantLogs/mysqlERR.log
sudo cd /usr
MYSQL_RELEASE_FILE="mysql57-community-release-el7-11.noarch.rpm"
sudo wget https://dev.mysql.com/get/$MYSQL_RELEASE_FILE 2>>LOG

#if [ -e $MYSQL_RELEASE_FILE ]
#then
sudo rpm -ivh $MYSQL_RELEASE_FILE
sudo yum install -y mysql-server
sudo rm -r $MYSQL_RELEASE_FILE
sudo systemctl start mysqld
	# sudo rpm -ivh $MYSQL_RELEASE_FILE
	# sudo yum install -y mysql-server
	# sudo rm -r $MYSQL_RELEASE_FILE
	# sudo systemctl start mysqld
#get mysql root pass from mysqld.log
#MYSQL_ROOT_PASSWORD_FIELD=$(grep 'temporary password' /var/log/mysqld.log | gawk '{print NF}')
#MYSQL_ROOT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | gawk '{print($MYSQL_ROOT_PASSWORD_FIELD)}')
sudo MYSQL_ROOT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log|cut -d " " -f 11)

#running secure_installation script
sudo SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter password for user root:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"New password:\"
send \"$MYSQL_NEW_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_NEW_ROOT_PASSWORD\r\" 
expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
send \"n\r\"
expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
#fi

echo "$SECURE_MYSQL"

sudo yum erase -y expect

#sudo echo $TP>/opt/tp.txt
sudo echo "MYSQL_NEW_ROOT_PASSWORD = $MYSQL_NEW_ROOT_PASSWORD">/opt/mysql.txt

echo "Mysql section FINISHED!!"
