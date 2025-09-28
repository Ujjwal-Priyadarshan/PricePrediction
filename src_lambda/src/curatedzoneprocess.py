
import boto3
import pandas as pd


import io

def handler(event, context):
    try:
        # Extract bucket and object key from the S3 event
        record = event['Records'][0]
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']

        print(f"Processing file: s3://{bucket_name}/{object_key}")

        # Download the CSV file from S3
        s3_client = boto3.client('s3')
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        csv_content = response['Body'].read()

        print(f"read csv_content {len(csv_content)}")

        # Load CSV into a Pandas DataFrame
        df = pd.read_csv(io.BytesIO(csv_content))

        selected_columns = ['CarName', 'fueltype', 'aspiration', 'doornumber', 'carbody', 'drivewheel', 'enginelocation', 'carheight', 'curbweight', 'cylindernumber', 'enginesize', 'compressionratio', 'horsepower', 'peakrpm', 'citympg', 'highwaympg', 'Price']
        df = df[selected_columns]
        features = ['CarName', 'fueltype', 'aspiration', 'doornumber', 'carbody', 'drivewheel', 'enginelocation', 'carheight', 'curbweight', 'cylindernumber', 'enginesize', 'compressionratio', 'horsepower', 'peakrpm', 'citympg', 'highwaympg']
        target = ['Price']

        categorical_features = ['CarName', 'fueltype', 'aspiration', 'doornumber', 'carbody', 'drivewheel', 'enginelocation']
        numeric_features = ['carheight', 'curbweight', 'cylindernumber', 'enginesize', 'compressionratio', 'horsepower', 'peakrpm', 'citympg', 'highwaympg']


        return {
            'statusCode': 200,
            'body': 'Model trained successfully'
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error processing file: {str(e)}"
        }
