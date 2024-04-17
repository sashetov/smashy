#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <load-balancer-arn> [<load-balancer-arn>...]"
    exit 1
fi

for lb_arn in "${@}"; do
    listeners=$(aws elbv2 describe-listeners --load-balancer-arn $lb_arn)
    listener_arns=$(echo $listeners | jq -r '.Listeners[] | select(.Port == 443) | .ListenerArn' | sort | uniq)
    for listener_arn in $listener_arns; do
        aws elbv2 describe-rules --listener-arn "$listener_arn" --query 'Rules[].Conditions[?Field==`host-header`].Values[]' --output text | while read host; do
            echo "$lb_arn $listener_arn $host";
        done;
    done
done
