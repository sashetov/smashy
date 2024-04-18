#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [<lambda-arn>...]"
fi
#set -x
L_ARN=$1
. funcs
if [ -z "$L_ARN" ] ; then
    aws lambda list-functions --query 'Functions[*].[FunctionArn,Role]' --output json | \
        jq -r '.[][]' | awk 'ORS=NR%2?" ":"\n"' | while read -r lambda_arn role_arn; do
        echo "$lambda_arn";
        echo " $role_arn";
        list_role_policies_docs "$role_arn";
    done
else
    for lambda_arn in "${@}"; do
        lambda_name=$(echo "$lambda_arn" | cut -d ':' -f 7);
        echo "$lambda_arn";
        role_arn=$(aws lambda get-function --function-name $lambda_name --query 'Configuration.Role' --output text)
        echo " $role_arn";
        list_role_policies_docs "$role_arn";
    done;
fi
