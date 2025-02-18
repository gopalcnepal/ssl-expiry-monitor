from flask import Flask
from flask_sqlalchemy import SQLAlchemy


app = Flask(__name__)

# Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'

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