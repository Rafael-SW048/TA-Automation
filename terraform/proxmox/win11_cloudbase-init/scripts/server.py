from flask import Flask
from flask_swagger_ui import get_swaggerui_blueprint
from vms import vms
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

SWAGGER_URL = '/api/docs'
API_URL = '/static/swagger.json'

swaggerui_blueprint = get_swaggerui_blueprint(
    SWAGGER_URL,
    API_URL,
    config={'app_name': "Test application"}
)

app.register_blueprint(swaggerui_blueprint, url_prefix=SWAGGER_URL)
app.register_blueprint(vms)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6969)
