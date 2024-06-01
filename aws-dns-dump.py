import sqlite3
import dns.resolver
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
import tqdm

# Define the database schema
def create_database():
    conn = sqlite3.connect('dnsdump.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS dnsdump (
            FQDN TEXT PRIMARY KEY,
            IP TEXT,
            CNAME TEXT,
            SOA TEXT,
            Reachable INTEGER,
            HTML_header TEXT,
            takeover TEXT
        )
    ''')
    conn.commit()
    conn.close()

# Insert or update a record in the database
def insert_or_update_record(record):
    conn = sqlite3.connect('dnsdump.db')
    c = conn.cursor()
    c.execute('''
        INSERT INTO dnsdump (FQDN, IP, CNAME, SOA, Reachable, HTML_header, takeover)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(FQDN) DO UPDATE SET
            IP=excluded.IP,
            CNAME=excluded.CNAME,
            SOA=excluded.SOA,
            Reachable=excluded.Reachable,
            HTML_header=excluded.HTML_header,
            takeover=excluded.takeover
    ''', record)
    conn.commit()
    conn.close()

# Resolve DNS records and update the database
def resolve_fqdn(fqdn):
    ip = cname = soa = html_header = takeover = None
    reachable = 0

    try:
        answers = dns.resolver.resolve(fqdn, 'A')
        ip = ', '.join([answer.to_text() for answer in answers])
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
        pass

    if not ip:
        try:
            answers = dns.resolver.resolve(fqdn, 'CNAME')
            cname = answers[0].to_text()
            try:
                cname_ip = dns.resolver.resolve(cname, 'A')
                ip = ', '.join([answer.to_text() for answer in cname_ip])
            except dns.resolver.NoAnswer:
                takeover = "true"
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
            pass

    if not ip and not cname:
        try:
            answers = dns.resolver.resolve(fqdn, 'SOA')
            soa = answers[0].to_text()
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
            pass

    if ip:
        try:
            response = requests.get(f'http://{fqdn}', timeout=5)
            html_header = '\n'.join(response.text.splitlines()[:3])
            reachable += 1
        except requests.RequestException:
            pass

        try:
            response = requests.get(f'https://{fqdn}', timeout=5)
            if html_header:
                html_header += '\n' + '\n'.join(response.text.splitlines()[:3])
            else:
                html_header = '\n'.join(response.text.splitlines()[:3])
            reachable += 1
        except requests.RequestException:
            pass

    record = (fqdn, ip, cname, soa, reachable, html_header, takeover)
    insert_or_update_record(record)

# Read FQDNs from a file and process them
def process_file(filename, max_workers=10):
    with open(filename, 'r') as f:
        fqdns = [line.strip() for line in f.readlines()]

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(resolve_fqdn, fqdn): fqdn for fqdn in fqdns}

        for future in tqdm.tqdm(as_completed(futures), total=len(futures)):
            future.result()

if __name__ == "__main__":
    create_database()
    process_file('fqdns.txt')
