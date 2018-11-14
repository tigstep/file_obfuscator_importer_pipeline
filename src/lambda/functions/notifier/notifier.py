import json
import boto3
import os

def lambda_handler(event, context):
    event_map = json.loads(event)

    failure_subject = "File Onboarding Failed"
    failure_message = 'File onboarding failed for file {}'

    success_subject = "File Onboarding Succeeded"
    success_message = "File onboarding succeeded for file {}"

    sns = boto3.client('sns')

    if event_map['result'] == 'success':
        sns.publish(
            TopicArn = os.environ['topic_arn'],
            Subject = success_subject,
            Message = success_message.format(event_map['key'])
        )
    else:
        sns.publish(
            TopicArn = os.environ['topic_arn'],
            Subject = failure_subject,
            Message = failure_message.format(event_map['key'])
        )
