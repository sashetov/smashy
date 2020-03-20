#!/usr/bin/env python3
"""
gets the instance id's of the ec2's in all asg's with prefix and terminates each
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
def get_asgs_with_prefix(sess, asg_name_prefix):
    """
    gets the asg names that start with the prefix provided
    """
    service = "autoscaling"
    client = sess.client(service)
    try:
        asgs = client.describe_auto_scaling_groups()
    except Exception as error: # pylint: disable = broad-except
        print(error)
        return False
    asgs = asgs["AutoScalingGroups"]
    pattern = '^' + asg_name_prefix
    rex = re.compile(pattern)
    asgs = [asg["AutoScalingGroupName"] \
            for asg in asgs if rex.match(asg["AutoScalingGroupName"])]
    return asgs
def delete_asgs(sess, asg_names):
    """
    deletes all asgs and associated instances
    """
    service = "autoscaling"
    client = sess.client(service)
    ress = []
    for asg_name in asg_names:
        try:
            res = client.delete_auto_scaling_group(
                AutoScalingGroupName=asg_name, ForceDelete=True)
            ress.append(res)
        except Exception as error: # pylint: disable = broad-except
            print(error)
            return False
    asgs_del_res = ress
    return ress
def get_launch_configs_with_prefix(sess, asg_name_prefix):
    """
    get the launch configs with the prefix provided
    """
    service = "autoscaling"
    client = sess.client(service)
    try:
        lcs = client.describe_launch_configurations()
    except Exception as error: # pylint: disable = broad-except
        print(error)
        return False
    lcs = lcs["LaunchConfigurations"]
    pattern = '^' + asg_name_prefix
    rex = re.compile(pattern)
    lcs = [lc["LaunchConfigurationName"] \
           for lc in lcs if rex.match(lc["LaunchConfigurationName"])]
    return lcs
def delete_lcs(sess, lcs_names):
    """
    delete launch configs
    """
    service = "autoscaling"
    client = sess.client(service)
    ress = []
    for lc_name in lcs_names:
        try:
            res = client.delete_launch_configuration(
                LaunchConfigurationName=lc_name)
            ress.append(res)
        except Exception as error: # pylint: disable = broad-except
            print(error)
            return False
    return ress
def get_stacks_with_prefix(sess, stack_prefix):
    """
    gets all cf stacks with stack prefix
    """
    service = "cloudformation"
    client = sess.client(service)
    try:
        asgs = client.describe_stacks()
    except Exception as error: # pylint: disable = broad-except
        print(error)
        return False
    asgs = asgs["Stacks"]
    pattern = '^' + stack_prefix
    rex = re.compile(pattern)
    asgs = [asg["StackName"] for asg in asgs if rex.match(asg["StackName"])]
    return asgs
def delete_stacks(sess, stack_names):
    """
    deletes all cf stacks with prefix
    """
    service = "cloudformation"
    client = sess.client(service)
    ress = []
    for stack_name in stack_names:
        try:
            res = client.delete_stack(StackName=stack_name)
            ress.append(res)
        except Exception as error: # pylint: disable = broad-except
            return {"status": 500, "msg": str(error)}
    for res in ress:
        if res["ResponseMetadata"]["HTTPStatusCode"] != 200:
            return  {"status": res["ResponseMetadata"]["HTTPStatusCode"], \
                     "msg": res}
    return {"status": 200, "msg":ress}
def main():
    """ entry point of program """
    progname = sys.argv[0]
    args = sys.argv[1:]
    argc = len(args)
    if argc < 3:
        print("Usage:\n{} ROLE_ARN REGION ASG_NAME_PREFIX\n"
              .format(progname))
        sys.exit(1)
    else:
        role_arn = args[0]
        region = args[1]
        asg_name_prefix = args[2]
    sess = get_session(role_arn, region)
    stacks = get_stacks_with_prefix(sess, asg_name_prefix)
    stacks_delete_res = delete_stacks(sess, stacks)
    asgs = get_asgs_with_prefix(sess, asg_name_prefix)
    delete_asgs(sess, asgs)
    lcs = get_launch_configs_with_prefix(sess, asg_name_prefix)
    delete_lcs(sess, lcs)
    dump_pretty(stacks_delete_res)
if __name__ == "__main__":
    main()
