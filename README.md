All Files in this repository are Copyright 2024 Russ Spooner ([spooner@gmail.com](mailto:spooner@gmail.com)), use or reproduction without permission is prohibited

* The shell script is used to interrogate R53 Hosted Zones in an AWS account and retrieve a list of subdomains for each.
* The Python script can then be used to iterate various DNS entries for the FQDNs listed in a text file and are insterted in a SQLite database.

Requires: tqdm, dnspython, requests
