import json
import boto3
def lambda_handler(event, context):
    cause_obj = json.loads(event['Cause'])
    def lambda_handler(event, context):


    sns = boto3.client('sns')
    sns.publish(
        TopicArn = 'arn:aws:sns:ap-southeast-2:123456789012:stack',
        Subject = 'File uploaded: ' + key,
        Message = 'File was uploaded to bucket: ' + bucket
    )
    return {
        "errorMessage": cause_obj["errorMessage"]
    }
