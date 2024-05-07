from flask import Blueprint
from routes.version1.vms import vms

v1_route = Blueprint('v1', __name__, url_prefix='/v1')
v1_route.register_blueprint(vms, url_prefix='/vms')