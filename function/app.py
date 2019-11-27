import os
import time
import boto3

cloudwatchLogs = boto3.client('logs')
retentionInDays = os.environ['CW_RETENTION_PERIOD']

def setRetention(logGroupName):
    cloudwatchLogs.put_retention_policy(logGroupName=logGroupName, retentionInDays=int(retentionInDays))
    print('Retention has been set to ' + retentionInDays + ' for ' + logGroupName)

def determineIfRetentionNeeded(logGroupName):
    # Check to see if log group has Retention property
    # If it has the Retention property, it skips the group and leaves the retention as it is
    # If it does not find the property, it will set the retention
    logGroups = cloudwatchLogs.describe_log_groups(logGroupNamePrefix=logGroupName)['logGroups']
    for groups in logGroups:
        try:
            retention = groups['retentionInDays']
            print("Retention is already set")
        except KeyError:
            setRetention(logGroupName)

def lambda_handler(event, context):
    # Wait for 10 seconds for log to finish creating
    time.sleep(10)
    logGroupName = event["detail"]["requestParameters"]["logGroupName"]
    determineIfRetentionNeeded(logGroupName)

    return True
