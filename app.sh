#!/bin/bash

####################################################
#Project section			   #
####################################################
LOG="/var/log/vagrantLogs/appERR.log"

# sudo yum install -y git 2>>$LOG
cd /opt
sudo git clone https://github.com/if-078/TaskManagmentWizard-NakedSpring-.git 2>>$LOG

#reading mysql root pass from file
TP=$(cat /opt/mysql.txt | cut -d " " -f 3)

#creating variable with twm user pass.
TMWPASS='1a_ZaraZa@'

#creating twm base and user
sudo mysql -uroot -p$(echo $TP) -e "CREATE DATABASE tmw DEFAULT CHARSET = utf8 COLLATE = utf8_unicode_ci;" 2>>$LOG
sudo mysql -uroot -p$(echo $TP) -e "GRANT ALL ON tmw.* TO 'tmw'@'localhost' IDENTIFIED BY '$TMWPASS';" 2>>$LOG
echo "TMW database and user created"

#change directory to TMW application
cd /opt/T*
cd src/test/resources

#import tmw database
sudo mysql -u tmw -p$TMWPASS tmw <create_db.sql 2>>$LOG
sudo mysql -u tmw -p$TMWPASS tmw <set_dafault_values.sql 2>>$LOG

cd /opt/T*
MCONF=src/main/resources/mysql_connection.properties
sudo sed -i 's/jdbc.username=root/jdbc.username=tmw/g' $MCONF 2>>$LOG
sudo sed -i 's/jdbc.password=root/jdbc.password='$TMWPASS'/g' $MCONF 2>>$LOG

#add input rules
sudo firewall-cmd --permanent --zone=public --add-port=8585/tcp 2>>$LOG
sudo firewall-cmd --reload 2>>$LOG

##This branch for using iptables
#sudo iptables -I INPUT -p tcp -m tcp --dport 8585 -j ACCEPT
##change iptables settings
#sudo sed -i 's/IPTABLES_SAVE_ON_STOP=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config
#sudo sed -i 's/IPTABLES_SAVE_ON_RESTART=\"no\"/IPTABLES_SAVE_ON_STOP=\"yes\"/g' /etc/sysconfig/iptables-config

##run application
mvn tomcat7:run-war 2>>$LOG
