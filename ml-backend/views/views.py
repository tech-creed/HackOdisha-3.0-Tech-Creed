from flask import jsonify, request
from PIL import Image
import pytesseract

from app import *

@app.route('/', methods = ['GET', 'POST'])
def home(imagePath):
    data = pytesseract.image_to_string(Image.open('test.png'))

    return jsonify({'data': data})