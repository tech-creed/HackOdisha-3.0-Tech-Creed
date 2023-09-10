from flask import jsonify, request
from app import *

@app.route('/', methods = ['GET', 'POST'])
def home():
    return jsonify({'data': 'hello'})