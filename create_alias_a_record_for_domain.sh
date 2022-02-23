#!/bin/bash
function ee (){
    echo $*
      eval $*
    }
    if [ $# -lt 5 ]; then 
        echo Usage: $0 CN PROFILE ZONEID_HOSTED ZONEID_CONTROLLED DNSNAME
          exit 1
    fi
    CN=$1
    PROFILE=$2
    ZONEID_HOSTED=$3
    ZONEID_CONTROLLED=$4
    DNSNAME=$5

    TMPF=$(mktemp)
    cat <<E > $TMPF
{
  "Comment": "Creating Alias resource record sets in Route 53",
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "$CN.",
      "Type": "A",
      "AliasTarget":{
        "HostedZoneId": "$ZONEID_HOSTED",
        "DNSName": "$DNSNAME.",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
E

cat $TMPF
ee aws --profile $PROFILE \
    route53 change-resource-record-sets \
      --hosted-zone-id $ZONEID_CONTROLLED --change-batch file://$TMPF
rm  -f $TMPF
