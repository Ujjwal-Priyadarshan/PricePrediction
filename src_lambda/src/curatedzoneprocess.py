
import boto3
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
import joblib
import numpy as np

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

        # training: prepare features lists.
        features = ['fueltype','aspiration','doornumber','carbody','drivewheel','enginelocation','color','wheelbase','carlength','carwidth','carheight','curbweight','cylindernumber','enginesize','compressionratio','horsepower','peakrpm','citympg','highwaympg']

        target = 'Price'

        numeric_features = ['wheelbase','carlength','carwidth','carheight','curbweight','cylindernumber','enginesize','compressionratio','horsepower','peakrpm','citympg','highwaympg']

        category_features = ['fueltype','aspiration','doornumber','carbody','drivewheel','enginelocation','color']

        # training: prepare imputers and pipelines
        print('prepare imputers and pipelines')

        categorical_imputer = SimpleImputer(strategy='most_frequent')
        numeric_imputer = SimpleImputer(strategy='mean')
        preprocessor = ColumnTransformer(transformers=[
            ('cat', Pipeline([
                ('imputer', categorical_imputer),
                ('encoder', OneHotEncoder(handle_unknown='ignore'))
            ]), category_features),
            ('num', numeric_imputer, numeric_features)
        ])

        pipeline = Pipeline(steps=[
            ('preprocessor', preprocessor),
            # ('regressor', LinearRegression())
            ('RandomForest', RandomForestRegressor(random_state=42))
        ])

        x = df[features]
        y = df[target]
        x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.1, random_state=42)

        # training: train the model pipeline
        print('train the model pipeline')
        pipeline.fit(x_train, y_train)

        # validation: testing the model
        print('testing the model')
        y_pred = pipeline.predict(x_test)
        mse = mean_squared_error(y_test, y_pred)

        # Output results
        print("Predicted Prices:", y_pred)
        print("Mean Squared Error:", mse)

        # Error analysis
        y_test = np.array(y_test)
        y_pred = np.array(y_pred)

        diff  = y_test - y_pred
        print(f" mean = {diff.mean()} \n max= {diff.max()} \n min = {diff.min()} \n standard deviation = {diff.std()}")

        #serialize and save the model for reuse
        print('saving the model for reuse in target bucket')
        temp_path = "/tmp/model.priceprediction.pkl"
        joblib.dump(pipeline, temp_path)

        s3_client.upload_file(temp_path, "ujp.target.zone", "models/model.priceprediction.pkl")

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
