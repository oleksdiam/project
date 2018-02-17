#!/bin/bash

### Host OS CentOS 7
# according to   	https://www.vultr.com/docs/how-to-install-sonarqube-on-centos-7
# with 			https://search.yahoo.com/yhs/search?hspart=ddc&hsimp=yhs-linuxmint&type=__alt__ddc_linuxmint_com&p=jenkins
# and 			https://docs.sonarqube.org/display/SONAR/Requirements

# Declare variables

#creating variable with user passwords.
POSTGRE_ROOT_PASS='la_3araZa'	#username=postgres
DB_USERPASS='1a_3araZa'			#username=sonar
SONAR_PASS='la_3araZa'			#username=sonar

JAVA_DOWNLOAD_LINK="http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.rpm"
JAVA_PACKAGE=$(echo $JAVA_DOWNLOAD_LINK|cut -d '/' -f 9)

POSTGRE_LINK="https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm"

SONAR_LINK="https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.7.1.zip"

#Create user environment variables file
VAR_FILE="/etc/profile.d/varapp.sh"
echo '#!/bin/bash
export JAVA_HOME=/usr/jdk
export JRE_HOME=/usr/jdk/jre

export PATH=$PATH:$JAVA_HOME"/bin":$JRE_HOME"/bin"' > $VAR_FILE

# Make sure we run script with root privileges
 if [ $UID != 0 ];
 	then		# not root, use sudo   # $0=./script.sh  # $*=treat everything as one word  # exit $?=return into the bash
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

cd /var/log/vagrantLogs || mkdir /var/log/vagrantLogs
LOG=/var/log/vagrantLogs/baseSetupERR.log

yum install -y wget mc unzip git net-tools.x86_64 2>>$LOG 

# SetTimeZone
timedatectl set-timezone Europe/Kiev

yum install -y ntpdate 2>>$lOG
ntpdate -u pool.ntp.org 2>>$LOG   #command not found

#JavaSetup section	#
LOG="/var/log/vagrantLogs/javaERR.log"
cd /usr/local/src/ && wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "$JAVA_DOWNLOAD_LINK"
rpm -ihv $JAVA_PACKAGE 2>>$LOG
#creating version independent directory
ln -s /usr/java/jdk1.8.0_162 /usr/jdk 2>>$LOG

echo   "export ${JHOME_VAR}=${JHOME_VALUE}"
echo   "export ${JRE_VAR}=${JRE_VALUE}"
echo "export PATH=$PATH:${JHOME_VALUE}'/bin':${JRE_VALUE}'/bin':${MHOME_VALUE}'/bin'"

rm -f $JAVA_PACKAGE 2>>$LOG
echo "Java DONE!"

###################################################
#PostgreSQL SECTION				  #
###################################################
echo "!PostgreSQL section started!"

LOG=/var/log/vagrantLogs/postgresqlERR.log
cd /usr
# wget https://dev.mysql.com/get/$POSTGRE_RELEASE_FILE 2>>LOG
rpm -Uvh $POSTGRE_LINK
yum install -y postgresql96-server postgresql96-contrib   ##
/usr/pgsql-9.6/bin/postgresql96-setup initdb
	
# Edit the /var/lib/pgsql/9.6/data/pg_hba.conf to enable MD5-based authentication.
# Find the following lines and change peer to trust and idnet to md5.
sed -i.bak -e '/all.*all.*peer/s/peer/trust/' /var/lib/pgsql/9.6/data/pg_hba.conf
sed -i -e '/all.*all.*ident/s/ident/md5/' /var/lib/pgsql/9.6/data/pg_hba.conf

systemctl start postgresql-9.6 2>>LOG
systemctl enable postgresql-9.6 2>>LOG

##-------------------------------------### the byte below is not automated yet 
passwd postgres                     # la_3araZa		waiting for answer, repeating twice	howto automate???
su - postgres 							# Switch to the postgres user.

createuser sonar
psql  									# here we switch to psql shell

ALTER USER sonar WITH ENCRYPTED password 'la_3araZa';

CREATE DATABASE sonar OWNER sonar;
\q										# exiting from psql shell
exit 									# exiting  from postgresql user shell to sudo user
###-------------------------------------###

cd /opt
wget $SONAR_LINK
# sonarqube-6.7.1
unzip sonarqube-6.7.1.zip -d /opt
mv /opt/sonarqube-6.7.1 /opt/sonarqube
rm -f sonarqube-6.7.1.zip 2>>LOG
groupadd sonar
useradd -c "Sonar System User" -d /opt/sonarqube -g sonar -s /bin/bash sonar 	# by default disables password
chown -R sonar:sonar /opt/sonarqube


sed -i.bak -e '/jdbc.username=/s/^#//; /jdbc.username=/s/=/=sonar/;
				 /jdbc.password=/s/^#//; /jdbc.password=/s/=/=$SONAR_PASS/;
				 /jdbc.url=jdbc:postgresql:/s/^#//
				' sonar.properties

echo '[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/sonar.service

sed -i.bak -e '/RUN_AS_USER=/s/^#//; /RUN_AS_USER=/s/=/=sonar/' sonar.sh

# for current session
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 2048

sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 2048

echo 'sonarqube   -   nofile   65536
sonarqube   -   nproc    2048'

systemctl start sonar
systemctl enable sonar 		# Enable the SonarQube service to automatically start at boot time.
# systemctl status sonar 	# To check if the service is running, run:

# vi /etc/httpd/conf.d/sonar.postgre.local.conf

# '<VirtaulHost *:80>
#     ServerName sonar.postgre.local
#     ServerAdmin sonar@postgre.local
#     ProxyPreserveHost On
#     ProxyPass / http://localhost:9000/
#     ProxyPassReverse / http://localhost:9000/
#     TransferLog /var/log/httpd/sonar.postgre.local_access.log
#     ErrorLog /var/log/httpd/sonar.postgre.local_error.log
# </VirtualHost>'


	
# 	# yum install -y expect
# 	# SECURE_POSTGRE=$(expect -c "
# 	# set timeout 10
# 	# spawn mysql_secure_installation
# 	# expect \"Enter password for user root:\"
# 	# send \"$POSTGRE_ROOT_PASSWORD\r\"
# 	# expect \"New password:\"
# 	# send \"$POSTGRE_NEW_ROOT_PASSWORD\r\"
# 	# expect \"Re-enter new password:\"
# 	# send \"$POSTGRE_NEW_ROOT_PASSWORD\r\" 
# 	# expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
# 	# send \"n\r\"
# 	# expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
# 	# send \"y\r\"
# 	# expect \"Disallow root login remotely?\"
# 	# send \"y\r\"
# 	# expect \"Remove test database and access to it?\"
# 	# send \"y\r\"
# 	# expect \"Reload privilege tables now?\"
# 	# send \"y\r\"
# 	# expect eof
# 	# ")
# 	# sudo yum erase -y expect 2>>LOG

firewall-cmd --permanent --zone=public --add-port=5432/tcp 2>>$LOG
firewall-cmd --permanent --zone=public --add-port=9000/tcp 2>>$LOG
# firewall-cmd --permanent --zone=public --add-port=80/tcp 2>>$LOG
# firewall-cmd --permanent --zone=public --add-sevice=http 2>>$LOG
firewall-cmd --reload
# echo "$SECURE_POSTGRE"


# echo "POSTGRE_NEW_ROOT_PASSWORD = $POSTGRE_NEW_ROOT_PASSWORD">/opt/mysql.txt
