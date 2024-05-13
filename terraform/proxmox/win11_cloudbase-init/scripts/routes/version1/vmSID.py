from flask import jsonify, Blueprint
import logging

checkSID = Blueprint('checkSID', __name__, url_prefix='/checkSID')

def create_response(message, code, status='success', details=""):
    response = {status: {"code": code, "message": message}}
    if details:
        response["details"] = details
    return jsonify(response)

@checkSID.route('/<ip>', methods=['GET'])
def check_sid(ip):
    try:
        with open(f"/root/TA-Automation/terraform/proxmox/win11_cloudbase-init/vm_ip-address/{ip}.txt", "r") as file:
            first_line = file.readline().strip()
        return create_response("Success", 200, "success", details={"ip": ip, "SID": first_line}), 200
    except FileNotFoundError:
        logging.error("No SID found for the given IP address", exc_info=True)
        return create_response("No SID found for the given IP address", 404, "error"), 404