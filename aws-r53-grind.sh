#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 [--profile profile_name] [--config config_file] [--list-zones] [--hostnames-only]"
    echo "  --profile profile_name    Specify the AWS profile to use"
    echo "  --config config_file      Specify the AWS config file to use"
    echo "  --list-zones              List hosted zone IDs only"
    echo "  --hostnames-only          Output hostnames only"
    exit 1
}

# Initialize variables
PROFILE=""
CONFIG_FILE=""
LIST_ZONES=0
HOSTNAMES_ONLY=0

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="--profile $2"
            shift
            shift
            ;;
        --config)
            CONFIG_FILE="--config $2"
            shift
            shift
            ;;
        --list-zones)
            LIST_ZONES=1
            shift
            ;;
        --hostnames-only)
            HOSTNAMES_ONLY=1
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Get list of hosted zone IDs
HOSTED_ZONE_IDS=$(aws route53 list-hosted-zones $PROFILE $CONFIG_FILE --query 'HostedZones[*].Id' --output text | awk -F'/' '{print $3}')

if [[ $LIST_ZONES -eq 1 ]]; then
    echo "Hosted Zone IDs:"
    for ID in $HOSTED_ZONE_IDS; do
        echo $ID
    done
    exit 0
fi

# Loop through each hosted zone ID and list subdomains
for ID in $HOSTED_ZONE_IDS; do
    if [[ $HOSTNAMES_ONLY -eq 0 ]]; then
        echo "Hosted Zone ID: $ID"
    fi
    NEXT_RECORD_NAME=""
    NEXT_RECORD_TYPE=""

    while :; do
        if [[ -n $NEXT_RECORD_NAME && -n $NEXT_RECORD_TYPE ]]; then
            LIST_COMMAND="aws route53 list-resource-record-sets $PROFILE $CONFIG_FILE --hosted-zone-id $ID --query 'ResourceRecordSets[?Type==`\"A\"` || Type==`\"CNAME\"`].Name' --output text --start-record-name $NEXT_RECORD_NAME --start-record-type $NEXT_RECORD_TYPE"
        else
            LIST_COMMAND="aws route53 list-resource-record-sets $PROFILE $CONFIG_FILE --hosted-zone-id $ID --query 'ResourceRecordSets[?Type==`\"A\"` || Type==`\"CNAME\"`].Name' --output text"
        fi

        RESULT=$($LIST_COMMAND 2>&1)
        if [[ $? -ne 0 ]]; then
            if [[ $RESULT == *"NoSuchHostedZone"* ]]; then
                if [[ $HOSTNAMES_ONLY -eq 0 ]]; then
                    echo "No such hosted zone: $ID"
                fi
                break
            else
                if [[ $HOSTNAMES_ONLY -eq 0 ]]; then
                    echo "Error: $RESULT"
                fi
                break
            fi
        fi

        SUBDOMAINS=$(echo "$RESULT" | tr -d '\r')
        if [[ -z $SUBDOMAINS ]]; then
            break
        fi

        if [[ $HOSTNAMES_ONLY -eq 1 ]]; then
            echo "$SUBDOMAINS" | tr -s '\t' '\n'
        else
            echo "$SUBDOMAINS" | tr -s '\t' '\n'
        fi

        NEXT_RECORD_NAME=$(echo "$RESULT" | awk 'END {print $1}')
        NEXT_RECORD_TYPE="A"

        if [[ -z $NEXT_RECORD_NAME ]]; then
            break
        fi
    done
done