#!/bin/bash 
# This script loops until a PID is alive
# When the PID is no longer active send a wall post to all tty and an email to notify about it

##########
# CONFIG #
##########

#############
# FUNCTIONS #
#############

function isCommandAvailable 
{
    type -P $1 >/dev/null 2>&1 || { echo >&2 "Program '$1' is not installed. Please install it before executing this script"; exit 1; }
    return 0
}

#############

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

###############

function sendNotificationEmail() 
{
	local pid=$1
	local cmdline=$2
	local email=$3
	echo -e "This is an automatic notification to warn you the PID $pid ($cmdline) ended in '$HOSTNAME'.\n\nPlease check it." | mutt -s "Proccess ID $pid ended" $email 

}

###############

function sendNotificationWallPost() 
{
	local pid=$1
	local cmdline=$2
	echo -e "This is an automatic notification to warn you the PID $pid ($cmdline) ended in '$HOSTNAME'.\n\nPlease check it." | wall -n &

}

##########
## MAIN ##
##########

isCommandAvailable "mutt"
isCommandAvailable "wall"

pid_to_wait=$1
destination_email=$2
cmd_to_wait="<UNKNOWN_CMD_LINE>"
emailCorrect=1

if [[ "$pid_to_wait" == "" ]];then
	echo "Usage: $0 <PID_to_wait> [<email_to_send_notification>]"
	exit 1
fi

# Check if $2 is a correct email address if it was provided
if [[ $destination_email != "" ]];then
    isCorrectEmailAddress $destination_email
    emailCorrect=$?
fi

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
	if [[ "$destination_email" != "" ]];then
        echo "$pid_to_wait ended. Sending an email to notify to $destination_email"
        sendNotificationEmail $pid_to_wait $cmd_to_wait $destination_email
    fi
    sendNotificationWallPost $pid_to_wait $cmd_to_wait
else
	echo "Error. Provided email is not correct (for example: user@domain.com)"
	exit 2
fi

exit 0
