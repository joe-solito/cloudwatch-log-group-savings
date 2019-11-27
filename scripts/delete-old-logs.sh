
#!/usr/bin/env bash

# This script will delete CloudWatch Log Groups that are older than a certain timestamp
# Requires the AWS CLI and jq

# Set Variables

# The date you want to delete logs up to. Epoch timestamp in milliseconds. https://www.epochconverter.com/
DateToDeleteUpTo=1569510364000

# Debug Mode
DEBUGMODE="0"

# Functions

# Run  pre-script commands
. _pre_script_commands.sh

# Verify AWS CLI Credentials are setup
# http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
if ! grep -q aws_access_key_id ~/.aws/config; then
	if ! grep -q aws_access_key_id ~/.aws/credentials; then
		fail "AWS config not found or CLI not installed. Please run \"aws configure\"."
	fi
fi

# Check for AWS CLI profile argument passed into the script
# http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-multiple-profiles
if [ $# -eq 0 ]; then
	scriptname=`basename "$0"`
	echo "Usage: ./$scriptname profile"
	echo "Where profile is the AWS CLI profile name"
	echo "Using default profile"
	echo
	profile=default
else
	profile=$1
fi

# Check required commands
check_command "aws"
check_command "jq"


# Validate Variable
if [[ "$DateToDeleteUpTo" == "x" ]]; then
	echo "Enter the date to retain all CloudWatch Log Groups in all AWS regions. Possible value needs to be in Epoch milliseconds"
	read -r -p "Date to delete: " DateToDeleteUpTo
fi

if [ -z "$DateToDeleteUpTo" ]; then
	fail "Variable DateToDeleteUpTo must be set."
fi

if ! [[ "$DateToDeleteUpTo" =~ 0 ]]; then
	fail "Variable DateToDeleteUpTo outside of possible range or invalid."
fi

# Get list of all CloudWatch Log Groups older than 60 days
function ListLogGroups(){
	if [[ $DEBUGMODE = "1" ]]; then
		echo "Begin ListLogGroups Function"
	fi
	ListLogGroups=$(aws logs describe-log-groups --output json --query "logGroups[*].[creationTime < \`$DateToDeleteUpTo\`,logGroupName]" 2>&1)
	if [ ! $? -eq 0 ]; then
		fail "$ListLogGroups"
	# if echo "$ListLogGroups" | egrep -iq "error|not"; then
	# 	fail "$ListLogGroups"
	else
		ParseOldLogGroups=$(echo "$ListLogGroups" | jq -rc '.[]' | grep "true")
	fi
	if [ -z "$ParseOldLogGroups" ]; then
		echo "No Log Groups found older than timestamp."
	else
		echo "Log Groups in Region:"
		echo "$ParseOldLogGroups"
		echo
		DeleteOldLogGroups
	fi
}

# Delete Log Groups
function DeleteOldLogGroups(){
	if [[ $DEBUGMODE = "1" ]]; then
		echo "Begin DeleteOldLogGroups Function"
	fi
	TotalLogGroups=$(echo "$ParseOldLogGroups" | wc -l | rev | cut -d " " -f1 | rev)
	echo "TotalLogGroups: $TotalLogGroups"
	if [[ $DEBUGMODE = "1" ]]; then
		echo "~~~~"
		echo "Region: $Region"
		echo "TotalLogGroups: $TotalLogGroups"
		echo "~~~~"
		pause
	fi
	DeleteOldLogGroupsStart=1
	for (( DeleteOldLogGroupsCount=$DeleteOldLogGroupsStart; DeleteOldLogGroupsCount<=$TotalLogGroups; DeleteOldLogGroupsCount++ ))
	do
		LogGroup=$(echo "$ParseOldLogGroups" | nl | grep -w [^0-9][[:space:]]$DeleteOldLogGroupsCount | cut -f2 -d'"')
		if [[ $DEBUGMODE = "1" ]]; then
			echo "o0o0o0o"
			echo "Count: $DeleteOldLogGroupsCount"
			echo "LogGroup: $LogGroup"
			echo "o0o0o0o"
			pause
		fi
		DeleteOldLogGroups=$(aws logs delete-log-group --log-group-name $LogGroup --output=json 2>&1)
		if echo "$DeleteOldLogGroups" | egrep -iq "error|not"; then
			fail "$DeleteOldLogGroups"
		fi
		if [ -z "$DeleteOldLogGroups" ]; then
			echo "$LogGroup has been deleted"
		else
			fail "$DeleteOldLogGroups"
		fi
	done
}

HorizontalRule
ListLogGroups

completed