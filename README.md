THe shell script is used to interrogate R53 Hosted ZOnes in AWS and retrieve a list of subdomains for each.
The Python script can then be used to iterate various DNS entries for the FQDNs listed in a text file and are insterted in a SQLite database.

Requires: tqdm, dnslib, requests
