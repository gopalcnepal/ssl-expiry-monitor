from app import db

class SSLInfo(db.Model):
    __tablename__ = 'ssl_info'

    id = db.Column(db.Integer, primary_key=True)
    domain = db.Column(db.String(255), nullable=False)
    expiry_date = db.Column(db.Date, nullable=False)
    notes = db.Column(db.String(255), nullable=False)

    def __repr__(self):
        return f"<SSLInfo(id={self.id}, domain='{self.domain}', expiry_date='{self.expiry_date}', notes='{self.notes}')>"
