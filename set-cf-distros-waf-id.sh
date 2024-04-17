#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Usage: $0 <waf_acl_id> <distribution_id> [<distribution_id> ...]";
    exit 1;
fi;
WAF_ACL_ID="$1"
for D in "${@:2}"; do
    aws cloudfront get-distribution-config --id $D > $D.json;
    ETAG=$(cat $D.json | jq -r '.ETag')
    echo ETAG:$ETAG
    jq ".DistributionConfig.WebACLId = \"$WAF_ACL_ID\"" $D.json | jq ".DistributionConfig" > $D-mod.json;
    mv $D-mod.json $D.json;
    echo aws cloudfront update-distribution --id $D --distribution-config file://$D.json --if-match $ETAG;
    aws cloudfront update-distribution --id $D --distribution-config file://$D.json --if-match $ETAG || { echo "Error: failed to update $D"; exit 1; };
    rm -f $D.json;
done;
