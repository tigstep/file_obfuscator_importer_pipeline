import os
import json
import boto3
import re
import mysql.connector

def lambda_handler(event, context):
    QUERY = '''
        SELECT FIELD_NM
        FROM T_MASKER_CONFIG
        WHERE PII_FLG = 'Y'
        ;
    '''
    BUCKET_NAME = 'frbhackathon2018tf' # replace with your bucket name
    KEY = 'source/test.txt' # replace with your object key
    def create_connection():
        connection = mysql.connector.connect(user='user',
                                             password='password',
                                             host='host',
                                             database='database')
        return connection

    def get_pii_fields():
        connection = create_connection()
        cursor = connection.cursor()
        cursor.execute(QUERY)
        connection.close()
        myresult = cursor.fetchall()
        pii_field_arr = []
        for x in myresult:
            PII_ARR.append(str(x[0]))
        return pii_field_arr

    def copy_from_s3():
        s3 = boto3.resource('s3')
        s3.Bucket(BUCKET_NAME).download_file(KEY, '/tmp/test.txt')
        return

    copy_from_s3()

