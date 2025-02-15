from flask import Blueprint, redirect, render_template, request
from app.services import get_all_ssl_info, get_ssl_expiry, add_ssl_info


views = Blueprint('views', __name__)

@views.route('/')
def index():
    ssl_info = get_all_ssl_info()
    return render_template('index.html', ssl_info=ssl_info)

@views.route('/add', methods=['GET', 'POST'])
def add():
    if request.method == 'POST':
        domain = request.form.get('domain')
        expiry_date = get_ssl_expiry(domain)
        notes = request.form.get('notes')
        add_ssl_info(domain, expiry_date, notes)
        return redirect('/')
    return render_template('add_ssl_info.html')