
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

        # process: remove unwanted columns
        columns = [
        'CarName',
        'fueltype',
        'aspiration',
        'doornumber',
        'carbody',
        'drivewheel',
        'enginelocation',
        'wheelbase',
        'color',
        'carlength',
        'carwidth',
        'carheight',
        'curbweight',
        'cylindernumber',
        'enginesize',
        'compressionratio',
        'horsepower',
        'peakrpm',
        'citympg',
        'highwaympg',
        'Price']

        df = df[columns]
        # process: remove high cardinality columns to avoid risk of encoding complexity and overfitting.
        df.drop('CarName', axis=1, inplace=True)

        # process: replace numeric NaN's to median()
        numeric_feature_columns = [
        'wheelbase',
        'carlength',
        'carwidth',
        'carheight',
        'curbweight',
        'cylindernumber',
        'enginesize',
        'compressionratio',
        'horsepower',
        'peakrpm',
        'citympg',
        'highwaympg']

        for col in numeric_feature_columns:
            df[col] = df[col].fillna(df[col].median())

        category_columns = [
        'fueltype',
        'aspiration',
        'doornumber',
        'carbody',
        'drivewheel',
        'enginelocation',
        'color'
        ]

        for col in category_columns:
            df[col] = df[col].fillna(df[col].mode()[0])

        csv_buffer = io.StringIO()
        df.to_csv(csv_buffer, index=False)

        s3_client.put_object(Bucket="ujp.curated.zone", Key="curated_sample.csv", Body=csv_buffer.getvalue())

        return {
            'statusCode': 200,
            'body': 'data cleaned successfully'
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error processing file: {str(e)}"
        }
