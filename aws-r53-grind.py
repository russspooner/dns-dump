import argparse
import boto3
import botocore
import os

def list_hosted_zones(client):
    response = client.list_hosted_zones()
    return [zone['Id'].split('/')[-1] for zone in response['HostedZones']]

def list_subdomains(client, zone_id, hostnames_only):
    paginator = client.get_paginator('list_resource_record_sets')
    try:
        for page in paginator.paginate(HostedZoneId=zone_id):
            for record in page['ResourceRecordSets']:
                if record['Type'] in ('A', 'CNAME'):
                    if hostnames_only:
                        hostname=record['Name'].strip()
                        if hostname.endswith('.'):
                            hostname = hostname[:-1]
                        print(hostname)
                    else:
                        print(f"Zone ID: {zone_id} - {record['Name'].strip()}")
    except botocore.exceptions.ClientError as error:
        if error.response['Error']['Code'] == 'NoSuchHostedZone':
            print(f"No such hosted zone: {zone_id}")
        else:
            print(f"Error: {error}")

def main():
    parser = argparse.ArgumentParser(description="AWS Route 53 Hosted Zones and Subdomains Script")
    parser.add_argument('--profile', help="Specify the AWS profile to use")
    parser.add_argument('--config', help="Specify the AWS config file to use")
    parser.add_argument('--list-zones', action='store_true', help="List hosted zone IDs only")
    parser.add_argument('--hostnames-only', action='store_true', help="Output hostnames only")
    args = parser.parse_args()

    if args.config:
        os.environ['AWS_SHARED_CREDENTIALS_FILE'] = os.path.expanduser("~/.aws/credentials")
        os.environ['AWS_CONFIG_FILE'] = args.config

    session_params = {}
    if args.profile:
        session_params['profile_name'] = args.profile

    session = boto3.Session(**session_params)

    try:
        client = session.client('route53')
    except botocore.exceptions.NoCredentialsError:
        print("Error: Unable to locate credentials. Please provide a valid AWS credentials file or set AWS environment variables.")
        return

    hosted_zone_ids = list_hosted_zones(client)

    if args.list_zones:
        print("Hosted Zone IDs:")
        for zone_id in hosted_zone_ids:
            print(zone_id)
    else:
        for zone_id in hosted_zone_ids:
            if not args.hostnames_only:
                print(f"Hosted Zone ID: {zone_id}")
            list_subdomains(client, zone_id, args.hostnames_only)

if __name__ == "__main__":
    main()
