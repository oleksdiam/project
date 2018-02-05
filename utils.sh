#!/bin/bash

#basic setup
sudo yum update
sudo mkdir /var/log/vagrantLogs
LOG=/var/log/vagrantLogs/baseSetupERR.log
sudo rm -fr /etc/localtime 2>$LOG
sudo ln -s /usr/share/zoneinfo/Europe/Kiev /etc/localtime 2>>LOG
sudo yum install -y ntpdate 2>>$lOG
sudo ntpdate -u pool.ntp.org 2>>$LOG
sudo yum install -y wget 2>>$LOG
sudo yum install -y mc 2>>$LOG
sudo yum install -y net-tools.x86_64 2>>$LOG
#sudo yum install -y git 2>>$LOG 
