from flask import Blueprint, redirect, render_template, request
from app.services import delete_ssl_info, edit_ssl_info, get_all_ssl_info, get_ssl_expiry, add_ssl_info, update_expiry_date
from datetime import datetime


views = Blueprint('views', __name__)

@views.route('/')
def index():
    ssl_info = get_all_ssl_info()
    return render_template('index.html', ssl_info=ssl_info, datetime=datetime)

@views.route('/add', methods=['POST'])
def add():
    if request.method == 'POST':
        domain = request.form.get('domain')
        expiry_date = get_ssl_expiry(domain)
        notes = request.form.get('notes')
        add_ssl_info(domain, expiry_date, notes)
        return redirect('/')

@views.route('/update', methods=['GET'])
def update():
    update_expiry_date()
    return redirect('/')

@views.route('/delete/<int:id>', methods=['POST'])
def delete(id):
    delete_ssl_info(id)
    return redirect('/')

@views.route('/edit/<int:id>', methods=['POST'])
def edit(id):
    domain = request.form.get('domain')
    expiry_date = get_ssl_expiry(domain)
    notes = request.form.get('notes')
    edit_ssl_info(id, domain, expiry_date, notes)
    return redirect('/')
