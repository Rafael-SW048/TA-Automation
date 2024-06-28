from flask import jsonify, Blueprint
import glob
import logging
import requests
from routes.version1.config import Config
from routes.version1.helpers import create_response, check_node_availability

checkSID = Blueprint('checkSID', __name__, url_prefix='/checkSID')

logger = logging.getLogger(__name__)

@checkSID.route('/<ip>', methods=['GET'])
def check_sid(ip):
    try:
        logger.info("Checking SID for IP address: %s", ip)
        files = glob.glob(f"/root/TA-Automation/terraform/proxmox/win11_cloudbase-init/vm_ip-address/{ip}-*.txt")
        if not files:
            logger.info("No SID found for the given IP address locally. Checking in the secondary nodes...")

            for node in Config.SECONDARY_NODES:
                if check_node_availability(node):
                    logger.info(f"Node {node['name']} is available. Checking SID in node {node['name']}")
                    response = requests.get(f"{node['url']}/v1/checkSID/{ip}")
                    if response.status_code == 200:
                        logger.info(f"SID found in the secondary node {node['name']}")
                        return response.json(), 200
                    else:
                        logger.error(f"Secondary node {node['name']} returned error: {response.content}")
            logger.error("No SID found for the given IP address in any available secondary node")
            raise FileNotFoundError

        with open(files[0], "r") as file:
            first_line = file.readline().strip()
            second_line = file.readline().strip()
        logger.info("SID found for the given IP address: %s", first_line)
        return create_response("Success", 200, "success", details={"ip": ip, "SID": first_line, "username": second_line}), 200
    except FileNotFoundError:
        logger.error("No SID found for the given IP address", exc_info=True)
        return create_response("No SID found for the given IP address", 404, "error"), 404
    except Exception as e:
        logger.error("Error occurred while checking SID: %s", e, exc_info=True)
        return create_response("Internal server error", 500, "error"), 500