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
    def create_connection():
        connection = mysql.connector.connect(user='root',
                                             password='11111111',
                                             host='frbhackathon2018tf.cu6klmcvkstw.us-west-1.rds.amazonaws.com',
                                             database='frbhackathon2018tf')
        return connection
    def get_pii_fields():
        #conn_params = load_json()
        connection = create_connection()
        cursor = connection.cursor()
        cursor.execute(QUERY)
        connection.close()
        myresult = cursor.fetchall()
        pii_field_arr = []
        for x in myresult:
            PII_ARR.append(str(x[0]))
        return pii_field_arr
    def obfuscate():
