import mysql.connector
import json
cnx = mysql.connector.connect(user='root', password='11111111',
                              host='frbhackathon2018.cu6klmcvkstw.us-west-1.rds.amazonaws.com',
                              database='frbhackathon2018')

def lambda_handler(event, context):
    try:
        cursor = cnx.cursor()
        cursor.execute("""
            select count(*) from test;
        """)
        result = cursor.fetchall()
        print(result)
    finally:
        cnx.close()
    return {
        "statusCode": 200,
        "body": json.dumps('Hello from Lambda!')
    }