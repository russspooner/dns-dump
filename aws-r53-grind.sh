#!/bin/bash

# Function to list hosted zone IDs
list_hosted_zone_ids() {
    local profile=$1

    # List hosted zones and extract zone IDs
    zone_ids=$(aws --profile $profile route53 list-hosted-zones --query "HostedZones[].Id" --output text)

    # Output zone IDs
    echo "Hosted Zone IDs:"
    echo "$zone_ids"
}

# Function to list subdomains for each hosted zone
list_subdomains() {
    local profile=$1

    # List hosted zones and extract zone IDs
    zone_ids=$(aws --profile $profile route53 list-hosted-zones --query "HostedZones[].Id" --output text)

    # Loop through each hosted zone
    for zone_id in $zone_ids; do
        zone_id=$(echo $zone_id | sed 's/\/hostedzone\///')  # Remove /hostedzone/ prefix
        echo "Hosted Zone ID: $zone_id"
        echo "Subdomains:"

        # Attempt to list resource record sets for the hosted zone
        subdomains=$(aws --profile $profile route53 list-resource-record-sets --hosted-zone-id $zone_id --query "ResourceRecordSets[?Type == 'A'].Name" --output text 2>&1)

        # Check if the error code is "NoSuchHostedZone"
        if echo "$subdomains" | grep -q "NoSuchHostedZone"; then
            echo "No such hosted zone found with ID: $zone_id"
            continue
        fi

        # Output subdomains one per line
        if [ -n "$subdomains" ]; then
            echo "$subdomains" | tr '\t' '\n'
        else
            echo "No subdomains found."
        fi
        echo ""
    done
}

# Check command-line arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <command> <aws_profile>"
    echo "Commands:"
    echo "  list-zone-ids <aws_profile>        - List hosted zone IDs"
    echo "  list-subdomains <aws_profile>      - List subdomains for each hosted zone"
    exit 1
fi

command=$1
profile=$2

# Dispatch based on command
case $command in
    "list-zone-ids")
        list_hosted_zone_ids $profile
        ;;
    "list-subdomains")
        list_subdomains $profile
        ;;
    *)
        echo "Invalid command. Valid commands are: list-zone-ids, list-subdomains"
        exit 1
        ;;
esac
