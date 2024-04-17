#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <load-balancer-arn> [<load-balancer-arn>...]"
    exit 1
fi

for arn in "${@}"; do
    echo lb_arn: $arn;
    listeners=$(aws elbv2 describe-listeners --load-balancer-arn $arn)
    listener_arns=$(echo $listeners | jq -r '.Listeners[] | select(.Port == 443) | .ListenerArn' | sort | uniq)
    for listener_arn in $listener_arns; do
        echo "  listener_arn: $listener_arn"
        aws elbv2 describe-rules --listener-arn "$listener_arn" | jq '.Rules[] | select(.Actions[] | .Type == "redirect") | .Actions[].RedirectConfig.Host' -r | while read host; do
            echo "    redirect_action_host: $host";
        done;
    done
done
