#! /bin/bash
if [ $# -lt 5 ]; then
    echo "Usage: $0 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_ROLE_ARN SESS_NAME"
    exit 1;
fi;
unset  AWS_SESSION_TOKEN
export AWS_ACCESS_KEY_ID="${1}"
export AWS_SECRET_ACCESS_KEY="${2}"
export AWS_REGION="${3}"
export AWS_ROLE_ARN="${4}"
export SESS_NAME="${5}"
TEMP_ROLE=$(aws sts assume-role --role-arn "$AWS_ROLE_ARN" --role-session-name "$SESS_NAME")
export AWS_ACCESS_KEY_ID=$(echo $TEMP_ROLE | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $TEMP_ROLE | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $TEMP_ROLE | jq -r .Credentials.SessionToken)
env | grep -E "AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN" | while read line; do echo export $line; done;
