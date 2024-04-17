#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Usage: $0 <lambda-function-name> <utc-offset>"
    exit 1
fi
FUNC=$1
UTC_OFFSET=$2
python -c "import sys; sys.exit(0 if sys.argv[1].lstrip('-').isdigit() else 1)" "$UTC_OFFSET"
if [ $? -ne "0" ]; then
    echo "UTC offset must be a positive or negative integer"
    exit 1
fi
UTC_OFFSET=$(python3 -c 'print('$UTC_OFFSET'*60*60)')
LGN=$(aws lambda get-function --function-name $FUNC --query 'Configuration.LoggingConfig.LogGroup' --output text);
LSN=$(aws logs describe-log-streams --log-group-name $LGN --descending --limit 1 --order-by LastEventTime --query 'logStreams[0].logStreamName' --output text)
aws logs get-log-events --log-group-name $LGN --log-stream-name $LSN --query 'events[*].{timestamp: timestamp, message: message}' | jq -r '.[] | "\(.timestamp / 1000 + '$UTC_OFFSET'| todate) \(.message)"' 
