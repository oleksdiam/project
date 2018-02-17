#!/bin/bash

### Host OS CentOS 7
# according to   	https://www.vultr.com/docs/how-to-install-sonarqube-on-centos-7
# with 			https://michalwegrzyn.wordpress.com/2016/07/14/do-not-run-sonar-as-root/
# and 			https://docs.sonarqube.org/display/SONAR/Requirements

# Declare variables

#creating variable with user passwords.
POSTGRE_ROOT_PASS='la_3araZa'	#username=postgres
PSQL_USER=sonar
DB_USERPASS='1a_3araZa'			#username=sonar
SONAR_USER=sonar
SONAR_PASS='la_3araZa'			#username=sonar

JAVA_DOWNLOAD_LINK="http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.rpm"
JAVA_PACKAGE=$(echo $JAVA_DOWNLOAD_LINK|cut -d '/' -f 9)

POSTGRE_LINK="https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm"

SONAR_LINK="https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.7.1.zip"

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

#Create user environment variables file
VAR_FILE="/etc/profile.d/varapp.sh"

echo 'export JAVA_HOME=/usr/jdk
export JRE_HOME=/usr/jdk/jre

export PATH=$PATH:$JAVA_HOME"/bin":$JRE_HOME"/bin"' > $VAR_FILE

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
rpm -Uvh $POSTGRE_LINK 2>>LOG
yum install -y postgresql96-server postgresql96-contrib 2>>LOG  ##
/usr/pgsql-9.6/bin/postgresql96-setup initdb 2>>LOG
	
# Edit the /var/lib/pgsql/9.6/data/pg_hba.conf to enable MD5-based authentication.
# Find the following lines and change peer to trust and idnet to md5.
sed -i.bak -e '/all.*all.*peer/s/peer/trust/; 
				/all.*all.*ident/s/ident/md5/
				' /var/lib/pgsql/9.6/data/pg_hba.conf 2>>LOG

systemctl start postgresql-9.6 2>>LOG
systemctl enable postgresql-9.6 2>>LOG

##-------------------------------------### the byte below is not automated yet / not checked at all 
# passwd postgres                     # la_3araZa		waiting for answer, repeating twice	howto automate???
# su - postgres 							# Switch to the postgres user.

# createuser sonar
# psql  									# here we switch to psql shell
sudo -u postgres bash -c "psql -c \"CREATE USER '$PSQL_USER' WITH PASSWORD '$DB_USERPASS';\""
sudo -u postgres bash -c "psql -c \"ALTER USER '$PSQL_USER' WITH ENCRYPTED password '$DB_USERPASS';\""
sudo -u postgres bash -c "psql -c \"CREATE DATABASE sonar OWNER $SONAR_USER;\""
#\q										# exiting from psql shell
#exit 									# exiting  from postgresql user shell to sudo user
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
				' /opt/sonarqube/conf/sonar.properties

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

sed -i.bak -e '/RUN_AS_USER=/s/^#//; /RUN_AS_USER=/s/=/=sonar/' /opt/sonarqube/bin/sonar.sh

# for current session
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 2048

# for permanent use
echo 'sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 2048' > /etc/sysctl.d/99-sonarqube.conf

echo 'sonarqube   -   nofile   65536
sonarqube   -   nproc    2048' > /etc/limits.conf

firewall-cmd --permanent --zone=public --add-port=5432/tcp 2>>$LOG
firewall-cmd --permanent --zone=public --add-port=9000/tcp 2>>$LOG
# firewall-cmd --permanent --zone=public --add-port=80/tcp 2>>$LOG
# firewall-cmd --permanent --zone=public --add-sevice=http 2>>$LOG
firewall-cmd --reload

systemctl start sonar
systemctl enable sonar 		# Enable the SonarQube service to automatically start at boot time.
# systemctl status sonar 	# To check if the service is running, run:
