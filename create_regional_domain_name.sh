#!/bin/bash
function ee (){
  echo $*
  eval $*
}
if [ $# -lt 3 ]; then 
  echo Usage: $0 CN PROFILE CERT_ARN
  exit 1
fi
CN=$1
PROFILE=$2
CERT_ARN=$3

aws --profile $PROFILE apigateway create-domain-name \
  --domain-name $CN \
  --regional-certificate-arn $CERT_ARN \
  --endpoint-configuration types="REGIONAL"
