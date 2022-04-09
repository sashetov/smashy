#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: $0 LOG_GROUP_NAME"
    exit 1
fi
UNAMEO="$(uname -s)"
case "${UNAMEO}" in
    Linux*)  SF="-r";;
    Darwin*) SF="-E";;
esac
export LGN=$1
export LSN=$(aws logs  describe-log-streams --log-group-name $LGN | jq '.logStreams |= sort_by(.lastEventTimestamp) | .logStreams | last.arn' | sed $SF 's/^.+log-stream://g' | sed $SF 's/"$//g');
aws logs get-log-events --log-group-name $LGN --log-stream-name  $LSN  | jq '.events | .[].message' | sed $SF 's/"//g'