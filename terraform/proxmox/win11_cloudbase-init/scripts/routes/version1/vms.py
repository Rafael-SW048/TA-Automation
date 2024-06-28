from flask import request, Blueprint, json
from routes.version1.user_vm_config import (
    validate_and_fill_defaults, update_pci_data, add_vm_config, delete_vm_config, update_tfvars, get_config_path, load_hcl_config, pc_settings
)
from routes.version1.run_vm_creation import handle_request
import requests
import logging
import subprocess
from routes.version1.config import Config
from routes.version1.helpers import create_response, handle_subprocess, check_node_availability

vms = Blueprint('vms', __name__, url_prefix='/vms')

logger = logging.getLogger(__name__)

def redirect_to_available_node(vm_config):
    for node in Config.SECONDARY_NODES:
        if check_node_availability(node):
            logger.info(f"Node {node['name']} is available. Redirecting request to {node['name']}")
            response = requests.post(f"{node['url']}/v1/vms", json=vm_config)
            if response.status_code == 200:
                return response.content, response.status_code
            else:
                logger.error(f"Node {node['name']} returned error: {response.content}")
    return None, None

@vms.route('/', methods=['POST'])
def create_vm():
    try:
        vm_config = request.get_json()
        if not vm_config:
            raise ValueError("Request data is not JSON")
        logger.info("Received request to create VM with configuration: %s", vm_config)
        
        vm_sid = "vm-" + vm_config["SID"]
        vm_config = {vm_sid: vm_config}
        logger.info("Formatted data: %s", vm_config)
        
        validated_config = {key: validate_and_fill_defaults(value) for key, value in vm_config.items()}
        logger.info("Validated config: %s", validated_config)
        
        pci_updated_config = update_pci_data(validated_config)
        logger.info("PCI updated config: %s", pci_updated_config)
        
        revalidate_config = pc_settings(pci_updated_config)
        if revalidate_config:
            logger.info("Revalidated config: %s", revalidate_config)
            vm_config.update(revalidate_config)
        else:
            logger.info("No revalidation needed")
        
        if pci_updated_config[vm_sid]["node"] != Config.PRIMARY_NODE['name']:
            logger.info(f"VM is not configured to be created on {Config.PRIMARY_NODE['name']}. Checking secondary nodes.")
            content, status_code = redirect_to_available_node(vm_config)
            if content and status_code:
                return content, status_code
            else:
                return create_response("No available nodes to handle the request", 503, status='error'), 503
        else:
            logger.info(f"VM is configured to be created on {Config.PRIMARY_NODE['name']}. Adding VM configuration on {Config.PRIMARY_NODE['name']}")
            add_vm_config(pci_updated_config)
            handle_request(vm_sid)
            logger.info(f"VM configuration on {Config.PRIMARY_NODE['name']} added successfully. Creating VM in {Config.PRIMARY_NODE['name']}")
            return create_response(f"VM configuration on {Config.PRIMARY_NODE['name']} added successfully. Creating VM in {Config.PRIMARY_NODE['name']}", 200), 200

    except KeyError as e:
        logger.error("Missing key in VM configuration: %s. Request data: %s", e, vm_config, exc_info=True)
        return create_response(f"Missing key in VM configuration: {str(e)}", 400, status='error', details="Ensure all required keys are provided."), 400
    except ValueError as e:
        logger.error("Invalid data or operation: %s. Request data: %s", e, vm_config, exc_info=True)
        return create_response(str(e), 400, status='error'), 400
    except requests.exceptions.RequestException as e:
        logger.error("Request error: %s", e, exc_info=True)
        return create_response("Request error", 502, status='error'), 502
    except subprocess.CalledProcessError as e:
        logger.error("Subprocess error: %s", e, exc_info=True)
        return create_response("Subprocess error", 500, status='error'), 500
    except Exception as e:
        logger.error("Internal server error: %s", e, exc_info=True)
        return create_response("Internal server error", 500, status='error'), 500

@vms.route('/<vm_sid>', methods=['DELETE'])
def delete_vm(vm_sid):
    try:
        logger.info("Received request to delete VM with SID %s", vm_sid)
        hcl_config = load_hcl_config(get_config_path())
        
        if hcl_config["vm-" + vm_sid]["node"] != Config.PRIMARY_NODE['name']:
            logger.info(f"VM is not on {Config.PRIMARY_NODE['name']}. Checking secondary nodes.")
            for node in Config.SECONDARY_NODES:
                if check_node_availability(node):
                    logger.info(f"Node {node['name']} is available. Redirecting request to {node['name']}")
                    response = requests.delete(f"{node['url']}/v1/vms/{vm_sid}")
                    if response.status_code == 200:
                        return response.content, response.status_code
                    else:
                        logger.error(f"Node {node['name']} returned error: {response.content}")
            return create_response("No available nodes to handle the request", 503, status='error'), 503
        else:
            logger.info(f"VM is on {Config.PRIMARY_NODE['name']}. Deleting VM on {Config.PRIMARY_NODE['name']}")
            delete_vm_config(vm_sid)
            handle_request({"action": "delete", "sid": vm_sid})
            logger.info(f"VM configuration on {Config.PRIMARY_NODE['name']} deleted successfully. Deleting VM in {Config.PRIMARY_NODE['name']}")
            return create_response(f"VM configuration on {Config.PRIMARY_NODE['name']} deleted successfully. Deleting VM in {Config.PRIMARY_NODE['name']}", 200), 200

    except KeyError as e:
        logger.error("No VM with SID %s found", vm_sid, exc_info=True)
        return create_response(f"No VM with SID {vm_sid} found", 404, status='error'), 404
    except Exception as e:
        logger.error("Internal server error during deletion: %s", e, exc_info=True)
        return create_response("Internal server error", 500, status='error'), 500

@vms.route('/templates', methods=['GET'])
def check_vm_template():
    try:
        logger.info("Checking for VM templates")
        command = (
            'pvesh get /pools/Templates --output-format json | '
            'jq -r \'.members[] | select(.id | startswith("qemu")) | '
            '{id: (.id | split("/")[1]), name: .name}\''
        )
        output = handle_subprocess(command)
        
        lines = output.splitlines()
        json_objects = []
        json_object = []
        for line in lines:
            json_object.append(line)
            if line.strip() == '}':
                json_objects.append('\n'.join(json_object))
                json_object = []

        output = {json.loads(json_object)['name']: json.loads(json_object)['id'] for json_object in json_objects}
        update_tfvars(output)

        if not output:
            logger.info("No VM templates found")
            return create_response('No VM templates found', 200, details='No VM templates exist'), 200

        logger.info("VM templates retrieved successfully")
        return create_response('VM templates retrieved successfully', 200, details=list(output.keys())), 200
    except Exception as e:
        logger.error("Internal server error during template retrieval: %s", e, exc_info=True)
        return create_response("Internal server error", 500, status='error'), 500
