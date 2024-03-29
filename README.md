## Controlling costs of CloudWatch Log Storage
#### Helpful tools to manage log retention and to delete older log groups

While the costs-saved may be low, there is room to save nonetheless in CloudWatch log storage. Specifically, this post will look at how we can manage CloudWatch log group retention to save money. By default, logs are kept indefinitely and never expire. Overtime storage and usage of these logs can be costly. You can adjust the retention policy for each log group, keeping the indefinite retention, or choosing a retention periods between 10 years and one day.

When dealing with CloudWatch log groups, I found that it’s not always possible to create the log group with a set retention. It’s simple enough when creating the log group in the console and you can even set the retention in the resource properties when creating it in CloudFormation. When you create the log group using cli, boto3 or even if it is created automatically by other services, there is no one shot way to create the group and set its retention. Therefore, it is set to “never expire” until changed by a second command line command or some sort of corrective control.

Because of this, we needed a solution that would automatically change the retention of the log group after its initial creation. We want to make sure that if a log group is created with a set retention (done in console or CloudFormation), that it doesn’t get overwritten by the solution. The solution requires a CloudWatch Event, a python 3.8 based Lambda function and an IAM role to go with it. You can find the CloudFormation template in the repo along with the lambda code.

The lambda will cover any newly created log groups, but we still need to address existing groups. In the repo there is a bash script that will help with this. `change-all-cw-log-group-retention.sh` works by looking at all log groups that do not have the set default retention and changes them. The desired retention can be set at the top of the script. Retention is the number of days to retain the log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. 

So now we have a corrective control in place and we’ve addressed the log groups that already existed by setting their retention to a number other than “Never Expire”. When I implemented these tools in a client’s environment, they asked me to also delete any existing log groups that were older than the new set retention. In this case it was 60 days. So, the second script you’ll find in that scipts folder is `delete-old-logs.sh`. At the top of this script you will set the date that you will want to delete up to. Important note here is that the timestamp is an epoch timestamp in milliseconds. https://www.epochconverter.com/ is a site that will convert your date to the correct timestamp. The script will query the CloudWatch Log Groups for all groups that have a creation date less than your given timestamp and delete it. 

These are the three tools I used to address my customer’s concerns when it came to costs of Cloudwatch Log Group storage. If you have any comments, suggestions or new ideas, please share and contribute! Thanks.

More technical blog posts and industry information can be found here:
https://onica.com/blog/

The Cloudwatch log group retention script was forked off of https://github.com/swoodford/aws and modified by Joe Solito.
