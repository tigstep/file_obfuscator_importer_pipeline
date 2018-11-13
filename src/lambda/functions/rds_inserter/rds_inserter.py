import mysql.connector
import boto3
import json
import os

def lambda_handler(event, context):
    QUERY = 'INSERT INTO {} (LOAN_NBR,LOAN_TYPE,CUST_NAME,TAX_ID,ACTIVE_IND,SOURCE_CD,AMOUNT,BRANCH_NBR) VALUES ({});'
    def create_connection():
        connection = mysql.connector.connect(user=os.environ['user'],
                                             password=os.environ['password'],
                                             host=os.environ['endpoint'].split(':')[0],
                                             database='frbhackathon2018tf')
        return connection
    def extract_bucket_name(event):
        return json.loads(event)['bucket_name']

    def extract_file_names(event):
        return json.loads(event)['list_of_files']

    def download_file_from_s3(s3, bucket_name, key):
        s3.Bucket(bucket_name).download_file(key, '/tmp/test.txt')
        return

    def insert_into_rds(s3, conn, bucket_name, file_names):
        cursor = conn.cursor()
        for file in file_names:
            if 'obfs' in file:
                table_name = 'T_CUST_LOAN_OBFS'
            else:
                table_name = 'T_CUST_LOAN'
            download_file_from_s3(s3, bucket_name, file)
            with open('/tmp/test.txt') as local_file:
                header = local_file.readline()
                for line in local_file:
                    print(QUERY.format(table_name, line.rstrip('\n')))
                    cursor.execute(QUERY.format(table_name, line.rstrip('\n')))
            local_file.close()
        conn.close()
        return


    def main():
        s3 = boto3.resource('s3')
        file_names = extract_file_names(event)
        bucket_name = extract_bucket_name(event)
        conn = create_connection()
        insert_into_rds(s3, conn, bucket_name, file_names)

    main()