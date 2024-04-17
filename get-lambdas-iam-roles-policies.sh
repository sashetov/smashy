#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [<lambda-arn>...]"
fi
#set -x
L_ARN=$1
function list_role_policies_docs(){
    local role_arn=$1
    local role_name="${role_arn##*/}"
    aws iam get-role --role-name $role_name --query 'Role.AssumeRolePolicyDocument' --output json | jq -rc '.Statement[]' | sed 's/^/   /';
    aws iam list-attached-role-policies --role-name "${role_name}" --query 'AttachedPolicies[*].PolicyArn' --output text | tr '\t' '\n' | while read policy_arn; do
        echo $policy_arn | sed 's/^/  /';
        version_id=$(aws iam get-policy --policy-arn $policy_arn --query 'Policy.DefaultVersionId' --output text)
        aws iam get-policy-version --policy-arn $policy_arn --version-id $version_id --query 'PolicyVersion.Document' --output json | jq -cr '.Statement[]' | sed 's/^/   /';
    done
    aws iam list-role-policies --role-name $role_name --query 'PolicyNames[*]' --output text | tr '\t' '\n' | while read policy_name; do
        echo inline:${policy_name} | sed 's/^/  /';
        aws iam get-role-policy --role-name $role_name --policy-name $policy_name --query 'PolicyDocument' --output json | jq -rc '.Statement[]' | sed 's/^/   /';
    done
}
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
