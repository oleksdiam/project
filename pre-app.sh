#!/bin/bash

####################################################
#Project-depended apps section			   #
####################################################
LOG="/var/log/vagrantLogs/pr_appERR.log"

sudo yum install -y git 2>>$LOG

sudo yum install -y maven 2>>$LOG
