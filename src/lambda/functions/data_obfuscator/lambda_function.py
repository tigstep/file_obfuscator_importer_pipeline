import os
import json
import boto3
import re

def lambda_handler(event, context):
    try:
        obfuscated_file = open("/tmp/test_obfs.txt", "w")
        bucket_name = 'frbhackathon2018'
        ssn_re_pattern = '^(\d{3}-?\d{2}-?\d{4}|XXX-XX-XXXX)$'
        client = boto3.client('s3')
        obj = client.get_object(Bucket = bucket_name, Key='source/test.csv')
        lines = obj['Body'].read().splitlines(True)
        for line in lines:
            columns = str(line).split(',')
            replaced = ['###-##-####' if re.match(ssn_re_pattern,column) else column for column in columns]
            obfuscated_file.write(','.join(replaced))
            obfuscated_file.write('\n')
        obfuscated_file.close()
        client.put_object(Body = open("/tmp/test_obfs.txt", "rb").read(), Bucket = bucket_name, Key='production/test_obfs.csv')
        return {
            "statusCode": 200,
            "body": json.dumps('Hello from Lambda!')
        }
    except:
        raise Exception('Exception in dataObfuscator!')
