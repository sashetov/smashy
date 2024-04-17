#!/bin/bash
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <wafv2_acl_arn> <load-balancer-arn> [<load-balancer-arn>...]"
    exit 1
fi
WAFV2_ACL_ARN="$1"
shift # Skip the first argument for the loop
for LB_ARN in "$@"; do
    echo "aws wafv2 associate-web-acl --web-acl-arn '$WAFV2_ACL_ARN' --resource-arn '$LB_ARN'";
    aws wafv2 associate-web-acl --web-acl-arn $WAFV2_ACL_ARN --resource-arn $LB_ARN;
done
