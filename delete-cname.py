#!/usr/bin/env python3
"""
deletes a cname record to a value and then prints that info in json format
"""
import sys
import datetime
import json
import re
import boto3
from boto3.session import Session


def assume_role(role_arn):
    """ assumes a role and returns that role's creds """
    sts = boto3.client('sts')
    role_data = sts.assume_role(
        RoleArn=role_arn, RoleSessionName="assume_role_name")
    creds = role_data['Credentials']
    return creds


def convert_for_json(o):
    """ converts datetime and other non json.dumpable objects to string
    """
    if isinstance(o, datetime.datetime):
        return o.__str__()
    return o


def dump_pretty(thing):
    """ pretty prints a json string, converting undumpables to str first"""
    print(json.dumps(thing, indent=1, default=convert_for_json))


def get_session(role_arn, region):
    """
    gets an aws session to use with boto
    """
    creds = assume_role(role_arn)
    aws_access_key_id = creds['AccessKeyId']
    aws_secret_access_key = creds['SecretAccessKey']
    aws_session_token = creds['SessionToken']
    session = Session(
        region_name=region,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        aws_session_token=aws_session_token)
    return session


def get_cname_record_value(sess, record, zone_id):
    """gets cname record value for record"""
    service = "route53"
    r53 = sess.client(service)
    try:
        result = r53.list_resource_record_sets(HostedZoneId=zone_id,StartRecordName=record)
    except Exception as error: # pylint: disable = broad-except
        print(error)
        return False
    result = result["ResourceRecordSets"][0]["ResourceRecords"][0]['Value']
    return result


def delete_cname_record(sess, record, ttl, zone_id):
    """
    creates a CNAME record under zone pointint to hostname
    """
    service = "route53"
    r53 = sess.client(service)
    value = get_cname_record_value(sess, record, zone_id)
    try:
        result = r53.change_resource_record_sets(
            HostedZoneId=zone_id,
            ChangeBatch={
                'Comment': "delete{} in {}".format(record, zone_id),
                'Changes': [{
                    'Action': 'DELETE',
                    'ResourceRecordSet': {
                        'Name'  : record,
                        'Type'  : 'CNAME',
                        'TTL'   : int(ttl),
                        "ResourceRecords":[{"Value" : value}]
                    }
                }]
            }
        )
    except Exception as error: # pylint: disable = broad-except
        pattern = '^.*but it was not found.*$'
        rex = re.compile(pattern)
        if rex.match(str(error)):
            return {"msg" : "already deleted"}# is ok, probably already deleted
        print(error) #is not ok
        return False
    return result


def main():
    """ entry point of program """
    progname = sys.argv[0]
    args = sys.argv[1:]
    argc = len(args)
    if argc < 5:
        print("Usage:\n{} ROLE_ARN REGION RECORD_VALUE TTL ZONE_ID \n"
              .format(progname))
        sys.exit(1)
    else:
        role_arn = args[0]
        region = args[1]
        record_value = args[2]
        ttl = args[3]
        zone_id = args[4]
    sess = get_session(role_arn, region)
    res = delete_cname_record(sess, record_value, ttl, zone_id)
    dump_pretty(res)


if __name__ == "__main__":
    main()