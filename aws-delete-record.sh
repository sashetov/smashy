#!/bin/sh
if [ $# -lt 5 ]; then
    echo "Usage: $0 HOSTED_ZONE_ID RESOURCE_VALUE DNS_NAME RECORD_TYPE TTL"
    exit 1
fi;
HOSTED_ZONE_ID="$1"
RESOURCE_VALUE="$2"
DNS_NAME="$3"
RECORD_TYPE="$4"
TTL="$5"
function ee(){
    echo $*
    time eval $*
}
JSON_FILE=`mktemp`
(
cat <<EOF
{
    "Comment": "Delete single record set",
    "Changes": [
        {
            "Action": "DELETE",
            "ResourceRecordSet": {
                "Name": "$DNS_NAME.",
                "Type": "$RECORD_TYPE",
                "TTL": $TTL,
                "ResourceRecords": [
                    {
                        "Value": "${RESOURCE_VALUE}"
                    }
                ]
            }
        }
    ]
}
EOF
) > $JSON_FILE
echo "Deleting DNS Record set"
cat $JSON_FILE
ee aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://$JSON_FILE