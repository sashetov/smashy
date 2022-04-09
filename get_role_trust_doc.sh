#/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: $0 ROLE_NAME"
    exit 1
fi
ROLE_NAME=$1
aws iam get-role --role-name  $ROLE_NAME | \
    jq '.["Role"]["AssumeRolePolicyDocument"]' | cat