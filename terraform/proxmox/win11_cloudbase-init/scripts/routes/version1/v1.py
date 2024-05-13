from flask import Blueprint
from routes.version1.vms import vms
from routes.version1.vmSID import checkSID

v1_route = Blueprint('v1', __name__, url_prefix='/v1')
v1_route.register_blueprint(vms, url_prefix='/vms')
v1_route.register_blueprint(checkSID, url_prefix='/checkSID')