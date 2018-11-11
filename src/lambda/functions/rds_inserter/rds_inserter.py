import mysql.connector
import boto3
import json

def lambda_handler(event, context):
    def extract_bucket_name(event):
        return json.loads(event)['bucket_name']

    def extract_file_names(event):
        return json.loads(event)['list_of_files']

    def download_file_from_s3(s3, bucket_name, key):
        s3.Bucket(bucket_name).download_file(key, '/tmp/test.txt')
        return

    def insert_into_rds(s3, bucket_name, file_names):
        for file in file_names:
            download_file_from_s3(s3, bucket_name, file)
            with open('/tmp/test.txt') as file:
                for line in file:
                    print(line)
            file.close()
        return


    def main():
        s3 = boto3.resource('s3')
        file_names = extract_file_names(event)
        bucket_name = extract_bucket_name(event)
        insert_into_rds(s3, bucket_name, file_names)

    main()