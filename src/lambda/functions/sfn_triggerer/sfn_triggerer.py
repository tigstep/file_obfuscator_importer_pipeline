import json
import boto3
import time
import os

def lambda_handler(event, context):
    client = boto3.client("sts")
    account_id = client.get_caller_identity()["Account"]
    client = boto3.client('stepfunctions')
    ts = time.time()
    response = client.start_execution(
        stateMachineArn=os.environ['sfn_arn']
        ,name='frbhackathon2018_state_machine' + str(ts)
        ,input=str(event).replace('\'','\"')
    )
    return {
        "statusCode": 200,
        "body": json.dumps('Started frbhackathon2018_state_machine')
    }