#!/bin/bash
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <load-balancer-arn> <cert-arn>..."
    exit 1
fi
LOAD_BALANCER_ARN="$1"
LISTENER_SSL_ARNS=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN | jq -r '.Listeners [] | select(.Port== 443) | .ListenerArn' )
shift # Skip the first argument for the loop
echo $LISTENER_SSL_ARNS | tr ' ' '\n' | while read LISTENER_ARN; do 
    for CERT_ARN in "$@"; do
        aws elbv2 add-listener-certificates --listener-arn $LISTENER_ARN --certificates CertificateArn=$CERT_ARN
    done
done
