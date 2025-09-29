#!/bin/bash

ACTION=$1
export AWS_ID=`aws sts get-caller-identity --query Account --output text`
export LANDING_IMG_NAME=lambda_landing_img
export CURATED_IMG_NAME=lambda_curated_img

if [ "$AWS_ID" == "" ]; then
    echo AWS account not configured use "aws configure"
    exit
fi

if [ "$ACTION" == "publish" ]; then
    # read -p "enter the aws account id:" AWS_ID

    LANDING_IMG_URL=$AWS_ID.dkr.ecr.us-east-1.amazonaws.com/$LANDING_IMG_NAME:latest
    docker build -t $LANDING_IMG_NAME -f ./src_lambda/Dockerfile.landing ./src_lambda
    docker tag $LANDING_IMG_NAME:latest $LANDING_IMG_URL
    aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ID.dkr.ecr.us-east-1.amazonaws.com
    aws ecr create-repository --repository-name $LANDING_IMG_NAME
    docker push $LANDING_IMG_URL

    CURATED_IMG_URL=$AWS_ID.dkr.ecr.us-east-1.amazonaws.com/$CURATED_IMG_NAME:latest
    docker build -t $CURATED_IMG_NAME -f ./src_lambda/Dockerfile.curated ./src_lambda
    docker tag $CURATED_IMG_NAME:latest $CURATED_IMG_URL
    aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ID.dkr.ecr.us-east-1.amazonaws.com
    aws ecr create-repository --repository-name $CURATED_IMG_NAME
    docker push $CURATED_IMG_URL


    cd src_iac
    terraform init
    terraform apply
elif [ "$ACTION" == "cleanup" ]; then
    aws s3 rm s3://ujp.landing.zone --recursive
    aws s3 rm s3://ujp.curated.zone --recursive
    aws s3 rm s3://ujp.target.zone --recursive
    cd src_iac
    terraform destroy
    aws ecr delete-repository --repository-name $LANDING_IMG_NAME --force
    aws ecr delete-repository --repository-name $CURATED_IMG_NAME --force
fi


echo aws account id = $AWS_ID