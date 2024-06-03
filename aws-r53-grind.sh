#!/bin/bash

# Function to list hosted zone IDs
list_hosted_zones() {
    aws route53 list-hosted-zones --query 'HostedZones[*].Id' --output text | tr '\t' '\n' | sed 's#/hostedzone/##'
}

# Function to list subdomains for a given hosted zone ID
list_subdomains() {
    local hosted_zone_id=$1
    aws route53 list-resource-record-sets --hosted-zone-id $hosted_zone_id --query 'ResourceRecordSets[?Type==`A` || Type==`CNAME`].Name' --output text | tr '\t' '\n'
}

# Main script
main() {
    # Command line arguments
    PROFILE=""
    CONFIG_FILE=""
    LIST_ZONES_ONLY=false
    HOSTNAMES_ONLY=false

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --profile) PROFILE="$2"; shift ;;
            --config) CONFIG_FILE="$2"; shift ;;
            --list-zones) LIST_ZONES_ONLY=true ;;
            --hostnames-only) HOSTNAMES_ONLY=true ;;
            *) echo "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done

    # Set AWS profile and config file if specified
    if [ -n "$PROFILE" ]; then
        export AWS_PROFILE=$PROFILE
    fi
    if [ -n "$CONFIG_FILE" ]; then
        export AWS_CONFIG_FILE=$CONFIG_FILE
    fi

    # Check if AWS credentials are available
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "Error: Unable to locate credentials. Please configure your AWS credentials."
        exit 1
    fi

    # Get hosted zone IDs
    hosted_zone_ids=$(list_hosted_zones)

    if $LIST_ZONES_ONLY; then
        echo "Hosted Zone IDs:"
        echo "$hosted_zone_ids"
    else
        for zone_id in $hosted_zone_ids; do
            if ! $HOSTNAMES_ONLY; then
                echo "Hosted Zone ID: $zone_id"
            fi
            subdomains=$(list_subdomains $zone_id)
            if [ -n "$subdomains" ]; then
                echo "$subdomains"
            else
                echo "No subdomains found for hosted zone: $zone_id"
            fi
        done
    fi
}

# Execute main function
main "$@"
