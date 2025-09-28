#!/bin/bash
Action=$1

if [ "$Action" == "package" ]; then
    # pip install scikit-learn -t lambda_layer/python
    pip install -r requirements.txt -t lambda_layer/python
    cd lambda_layer
    find python/ -type d -name "tests" -exec rm -rf {} +
    find python/ -type f -name "*.so" -size +10M -delete
    rm -rf python/*/*.dist-info
    zip -r ../../src_iac/layer.zip .

elif [ "$Action" == "landing" ]; then
    cd src
    zip ../../src_iac/lambda_landing.zip landingzoneprocess.py

elif [ "$Action" == "curated" ]; then
    cd src
    zip ../../src_iac/lambda_curated.zip curatedzoneprocess.py

fi
