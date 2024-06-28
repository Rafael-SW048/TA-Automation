import os
import sys
from flask import Flask, redirect, jsonify
from flask_swagger_ui import get_swaggerui_blueprint
from routes.version1.v1 import v1_route
import logging
from routes.version1.run_vm_creation import start_request_processing, stop_request_processing
import signal

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("app.log"),
        logging.StreamHandler() 
    ]
)

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

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

try:
    versions = [name for name in os.listdir('scripts/routes') if os.path.isdir(os.path.join('scripts/routes', name))]
except FileNotFoundError:
    logging.error("No versions found in the routes directory. Exiting...")
    sys.exit(1)

@app.route('/')
def home():
    return f"Welcome to the API! You can specify the version of the API in the URL, like /api/v1 or /api/v2. Currently, the available versions are: {', '.join(versions)}."

# Signal handling
def signal_handler(sig, frame):
    logging.info("Stopping the server...")
    stop_request_processing()
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

# Start the request processing thread
processing_thread = start_request_processing()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 6969)))
