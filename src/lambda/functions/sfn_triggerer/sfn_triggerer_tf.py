import json
import boto3
import time

def lambda_handler(event, context):
    client = boto3.client("sts")
    account_id = client.get_caller_identity()["Account"]
    client = boto3.client('stepfunctions')
    ts = time.time()
    response = client.start_execution(
        stateMachineArn='arn:aws:states:us-west-1:' + account_id + ':stateMachine:frbhackathon2018_state_machine'
        ,name='frbhackathon2018_state_machine' + str(ts),input='{}'
    )
    return {
        "statusCode": 200,
        "body": json.dumps('Started frbhackathon2018_state_machine')
    }