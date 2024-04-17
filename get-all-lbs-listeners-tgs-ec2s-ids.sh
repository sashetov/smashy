#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <load-balancer-arn> [<load-balancer-arn>...]"
    exit 1
fi
#set -x
for LB_ARN in "${@}"; do
    LB_ARN="$1"
    echo "$LB_ARN"
    LS=$(aws elbv2 describe-listeners --load-balancer-arn $LB_ARN --query 'Listeners[].ListenerArn' | jq -r '.[]')
    for L in $LS; do
        echo " $L"
        TGS=$(aws elbv2 describe-rules --listener-arn $L --query 'Rules[].Actions[].TargetGroupArn' | jq -r '.[]' | sort | uniq )
        for TG in $TGS; do
            echo "  $TG"
            aws elbv2 describe-target-health --target-group-arn $TG --query 'TargetHealthDescriptions[].Target.Id' | jq -r '.[]' | sort | uniq | while read EC2; do
                echo "   $EC2"
            done
        done
    done
done
#set +x
