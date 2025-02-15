import ssl
import socket
from datetime import datetime
from app.models import SSLInfo
from app import db

def get_ssl_expiry(domain):
    try:
        context = ssl.create_default_context()
        with socket.create_connection((domain, 443)) as sock:
            with context.wrap_socket(sock, server_hostname=domain) as ssock:
                cert = ssock.getpeercert()
                expiry_date = datetime.strptime(cert['notAfter'], "%b %d %H:%M:%S %Y %Z")
                return expiry_date
    except Exception as e:
        return str(e)

def add_ssl_info(domain, expiry_date, notes):
    ssl_info = SSLInfo(domain=domain, expiry_date=expiry_date, notes=notes)
    db.session.add(ssl_info)
    db.session.commit()

def get_all_ssl_info():
    return SSLInfo.query.all()
