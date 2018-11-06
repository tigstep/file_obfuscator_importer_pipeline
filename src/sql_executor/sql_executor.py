import mysql.connector
import json
import os

def load_json():
    two_up = os.path.abspath(os.path.join(__file__ ,"../../.."))

    json_file = (os.path.join(two_up,'terraform/outputs.json'))
    with open(json_file) as f:
        conn_params = json.load(f)
    print(conn_params)
    return conn_params

def create_connection(conn_params):
    connection = mysql.connector.connect(user=conn_params['rds_username']['value'],
                                         password=conn_params['rds_password']['value'],
                                            host=conn_params['rds_endpoint']['value'].split(':')[0],
                                  database='frbhackathon2018tf')
    return connection
def execute_queries():
    conn_params = load_json()
    connection = create_connection(conn_params)
    cursor = connection.cursor()
    with open('queries.sql') as queries:
        for query in queries:
            cursor.execute(query)
    connection.close()

execute_queries()