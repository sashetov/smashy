#!/usr/bin/env python3
"""
gets the instance id's of the ec2's in a particular ASG
"""
import sys
import datetime
import json
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


def get_asg_ec2s(sess, asg_name):
    """
    gets the instance ids of instances bellonging to an asg
    """
    service = "autoscaling"
    client = sess.client(service)
    try:
        result = client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name])
    except Exception as error: # pylint: disable = broad-except
        print(error)
        return False
    return result


def main():
    """ entry point of program """
    progname = sys.argv[0]
    args = sys.argv[1:]
    argc = len(args)
    if argc < 3:
        print("Usage:\n{} ROLE_ARN REGION ASG_NAME\n"
              .format(progname))
        sys.exit(1)
    else:
        role_arn = args[0]
        region = args[1]
        asg_name = args[2]
    sess = get_session(role_arn, region)
    res = get_asg_ec2s(sess, asg_name)
    dump_pretty(res)


if __name__ == "__main__":
    main()