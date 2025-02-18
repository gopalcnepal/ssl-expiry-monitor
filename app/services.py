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

def edit_ssl_info(id, domain, expiry_date, notes):
    ssl_info = SSLInfo.query.get(id)
    ssl_info.domain = domain
    ssl_info.expiry_date = expiry_date
    ssl_info.notes = notes
    db.session.commit()

def update_expiry_date():
    ssl_info = get_all_ssl_info()
    for info in ssl_info:
        expiry_date = get_ssl_expiry(info.domain)
        info.expiry_date = expiry_date
        db.session.commit()

def delete_ssl_info(id):
    ssl_info = SSLInfo.query.get(id)
    db.session.delete(ssl_info)
    db.session.commit()
