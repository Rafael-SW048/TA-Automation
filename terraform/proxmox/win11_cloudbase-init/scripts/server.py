import os
from flask import Flask, redirect
from flask_swagger_ui import get_swaggerui_blueprint
from routes.version1.v1 import v1_route
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

SWAGGER_URL_V1 = '/api/docs/v1'
API_URL_V1 = '/static/swagger_v1.json'

swaggerui_v1 = get_swaggerui_blueprint(
    SWAGGER_URL_V1,
    API_URL_V1,
    config={'app_name': "Test application - Version 1"}
)

app.register_blueprint(swaggerui_v1, url_prefix=SWAGGER_URL_V1)
app.register_blueprint(v1_route)

@app.route('/v1')
def v1_redirect():
    return redirect(SWAGGER_URL_V1)

try:
    versions = [name for name in os.listdir('scripts/routes') if os.path.isdir(os.path.join('scripts/routes', name))]
except FileNotFoundError:
    print("The 'routes' directory does not exist. Please create it and try again.")
    sys.exit(1)

@app.route('/')
def home():
    return f"Welcome to the API! You can specify the version of the API in the URL, like /api/v1 or /api/v2. Currently, the available versions are: {', '.join(versions)}."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6969)