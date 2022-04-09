#!/bin/bash
function ee (){
  echo $*
  eval $*
}
if [ $# -lt 3 ]; then 
  echo Usage: $0 PASSFILE CN PROFILE
  exit 1
fi
PASSFILE=$1
CN=$2
PROFILE=$3
openssl rsa -in $CN-encrypted.key -out $CN.key -passin file:./$PASSFILE
aws --profile $PROFILE acm import-certificate --private-key=fileb://$CN.key --certificate=fileb://$CN.crt   --certificate-chain=fileb://$CN-chain.pem