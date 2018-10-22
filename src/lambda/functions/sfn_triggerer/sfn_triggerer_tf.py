import json
import boto3
import time

def lambda_handler(event, context):
    client = boto3.client('stepfunctions')
    ts = time.time()
    response = client.start_execution(stateMachineArn='arn:aws:states:us-west-1:178877070406:stateMachine:FileIngestorPipeline',name='test' + str(ts),input='{}')
    return {
        "statusCode": 200,
        "body": json.dumps('Hello from Lambda!')
    }