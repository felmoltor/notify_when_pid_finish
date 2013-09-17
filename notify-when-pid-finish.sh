#!/bin/bash

# This script loops until a PID is alive
# When the PID is no longer active send an email to notify it

##########
# CONFIG #
##########

function waitForPid()
{
	local PID=$1

	while [[ ( -d /proc/$PID ) && ( -z `grep zombie /proc/$PID/status` ) ]]; do
		sleep 10
	done
}

#############

function isCorrectEmailAddress()
{
	local regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
	if [[ $1 =~ $regex ]];then
		return 1
	else
		return 0
	fi
}

function sendNotificationEmail() 
{
	local pid=$1
	local cmdline=$2
	local email=$3
	echo -e "This is an automatic notification to warn you the PID $pid ($cmdline) ended in $HOSTNAME.\n\nPlease check it." | mutt -s "Proccess ID $pid ended" $email 

}

##########
## MAIN ##
##########

pid_to_wait=$1
destination_email=$2
cmd_to_wait="<UNKNOWN_CMD_LINE>"

if [[ ("$pid_to_wait" == "") || ("$destination_email" == "") ]];then
	echo "Usage: $0 <PID_to_wait> <email_to_send_notification>"
	exit 1
fi



# TODO: Check if $2 is a correct email address
isCorrectEmailAddress $destination_email
emailCorrect=$?

if [[ $emailCorrect == 1 ]];then
	
	if [[ $(ls -l /proc/$pid_to_wait | wc -l ) == 0 ]];then
		# This PID does not exists
		exit 1
	else
		cmd_to_wait=$(cat /proc/$pid_to_wait/cmdline)
		echo "Waiting for '$cmd_to_wait'"
	fi
	
	echo "Let's wait for PID $pid_to_wait..."
	waitForPid $pid_to_wait
	echo "$pid_to_wait ended. Sending an email to notify to $destination_email"
	sendNotificationEmail $pid_to_wait $cmd_to_wait $destination_email
else
	echo "Error. Provided email is not correct (for example: user@domain.com)"
	exit 2
fi

exit 0
