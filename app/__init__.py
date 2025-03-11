from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os


app = Flask(__name__)

# Configuration
server_env = os.getenv('SERVER_ENV', 'development').lower()
if server_env == 'production':
    # Use PostgreSQL for production
    postgres_user = os.getenv('POSTGRESQL_ADMIN_USER')
    postgres_password = os.getenv('POSTGRESQL_ADMIN_PASSWORD')
    postgres_host = os.getenv('POSTGRESQL_URL')
    postgres_db = os.getenv('POSTGRESQL_DATABASE_NAME')
    app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{postgres_user}:{postgres_password}@{postgres_host}:5432/{postgres_db}'
else:
    # Use SQLite for development
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///development.db'


# Initialize the database
db = SQLAlchemy(app)

# Register blueprints
from app.views import views
app.register_blueprint(views, url_prefix='/')

# Create the database tables
with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(debug=True)