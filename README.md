All Files in this repository are Copyright 2024 Russ Spooner ([spooner@gmail.com](mailto:spooner@gmail.com)), use or reproduction without permission is prohibited

# Overview

* The shell script is used to interrogate R53 Hosted Zones in an AWS account and retrieve a list of subdomains for each.
* The Python script can then be used to iterate various DNS entries for the FQDNs listed in a text file and are insterted in a SQLite database.

Requires: tqdm, dnspython, requests

# AWS Route 53 Hosted Zones and Subdomains Grinder

## Usage

```bash
$ ./aws-r53-grind.[sh|py] --help
Usage: ./aws-r53-grind.sh [--profile profile_name] [--config config_file] [--list-zones] [--hostnames-only]
  --profile profile_name    Specify the AWS profile to use
  --config config_file      Specify the AWS config file to use
  --list-zones              List hosted zone IDs only
  --hostnames-only          Output hostnames only
