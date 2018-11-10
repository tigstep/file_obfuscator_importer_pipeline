import os
import boto3
import mysql.connector

def lambda_handler(event, context):
    QUERY = '''
        SELECT FIELD_NM
        FROM T_MASKER_CONFIG
        WHERE PII_FLG = 'Y'
        AND FILE_NM = '{}'
        ;
    '''
    def extract_bucket_name(event):
        bucket_name = (event['Records'][0]['s3']['bucket']['name'])
        print("bucket_name_is : " + bucket_name)
        return bucket_name

    def extract_file_name(event):
        file_name = (event['Records'][0]['s3']['object']['key']).split("/")[1]
        return file_name

    def create_connection():
        connection = mysql.connector.connect(user=os.environ['user'],
                                             password=os.environ['password'],
                                             host=os.environ['endpoint'].split(':')[0],
                                             database='frbhackathon2018tf')
        return connection

    def get_pii_fields(file_name):
        connection = create_connection()
        cursor = connection.cursor()
        cursor.execute(QUERY.format(file_name))
        connection.close()
        query_result = cursor.fetchall()
        pii_field_arr = []
        for result in query_result:
            pii_field_arr.append(str(result[0]))
        return pii_field_arr

    def download_orig_from_s3(s3, bucket_name, source_key):
        s3.Bucket(bucket_name).download_file(source_key, '/tmp/test.txt')
        return

    def upload_obfs_to_s3(s3, bucket_name, file_name, obfs_key):
        s3.Bucket(bucket_name).upload_file(file_name, obfs_key)
        return

    def get_pii_indexes(header, file_name):
        pii_arr = get_pii_fields(file_name)
        index_arr = []
        header_arr = header.split(',')
        for elem in pii_arr:
            index_arr.append(header_arr.index(elem))
        return(index_arr)

    def obfuscate_file(s3, bucket_name, source_key, obfs_key, file_name):
        obfs_file_name = "/tmp/hello.txt"
        obfs_file = open(obfs_file_name,"w")
        download_orig_from_s3(s3, bucket_name, source_key)
        with open('/tmp/test.txt') as file:
            header = file.readline()
            index_arr = get_pii_indexes(header, file_name)
            obfs_file.write(header)
            for line in file:
                line_arr = line.split(',')
                for index in index_arr:
                    line_arr[index] = '########'
                obfs_file.write(','.join(line_arr))
        obfs_file.close()
        upload_obfs_to_s3(s3, bucket_name, obfs_file_name, obfs_key)
        return(obfs_file_name)

    def main():
        bucket_name = extract_bucket_name(event)
        file_name = extract_file_name(event)
        source_key = 'source/' + file_name
        print(source_key)
        obfs_key = 'obfs/' + file_name
        s3 = boto3.resource('s3')
        obfuscate_file(s3, bucket_name, source_key, obfs_key, file_name)

    main()