#!/bin/bash
function ee (){
  echo $*
  eval $*
}
if [ $# -lt 5 ]; then 
  echo Usage: $0 CN PROFILE REST_API_ID STAGE BASEPATH
  exit 1
fi
CN=$1
PROFILE=$2
REST_API_ID=$3
STAGE=$4
BASEPATH=$5
aws --profile $PROFILE \
  apigateway create-base-path-mapping \
  --domain-name $CN \
  --rest-api-id $REST_API_ID \
  --stage $STAGE \
  --base-path $BASEPATH
