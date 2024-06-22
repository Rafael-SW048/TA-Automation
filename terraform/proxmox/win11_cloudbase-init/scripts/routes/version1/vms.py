from flask import Flask, request, jsonify, Blueprint, json
import logging
from routes.version1.user_vm_config import validate_and_fill_defaults, update_pci_data, add_vm_config, delete_vm_config, update_tfvars, get_config_path, load_hcl_config, pc_settings
from routes.version1.run_vm_creation import handle_request
# from routes.version1.run_vm_creation_v2 import handle_request
import subprocess
import requests

import shutil

vms = Blueprint('vms', __name__, url_prefix='/vms')

def create_response(message, code, status='success', details=""):
    response = {status: {"code": code, "message": message}}
    if details:
        response["details"] = details
    return jsonify(response)



app = Flask(__name__)
@vms.route('/', methods=['POST'])
def create_vm():
    try:
        vm_config = request.get_json()
        if not vm_config:
            raise ValueError("Request data is not JSON")
        print("got a request", vm_config)
        vm_sid = "vm-" + vm_config["SID"]
        vm_config = {vm_sid: vm_config}
        print("formated data", vm_config)
        validated_config = {key: validate_and_fill_defaults(value) for key, value in vm_config.items()}
        print("validated: ", validated_config)
        
        pci_updated_config = update_pci_data(validated_config)
        print("pci updated: ", pci_updated_config)
        
        revalidate_config = pc_settings(pci_updated_config)
        if revalidate_config:
            print("revalidate: ", revalidate_config)
            vm_config.update(revalidate_config)
        else:
            print("no revalidate")
        
        other_node_url = "http://10.11.1.182:6969/v1/vms"  # Replace with the URL of your other node
        
        # Brute Force Cluster. Need Improvement
        if pci_updated_config[vm_sid]["node"] != "pve":
            # Forward the request to another node
            response = requests.post(other_node_url, json=vm_config)
            return response.content, response.status_code
        else:
            add_vm_config(pci_updated_config)
            handle_request(vm_sid)
            return create_response('VM configuration on PVE1 added successfully. Creating VM in PVE1', 200), 200
        
        # handle_request({"action": "create", "sid": sid})

    except KeyError as e:
        logging.error("Missing key in VM configuration", exc_info=True)
        return create_response(f"Missing key in VM configuration: {str(e)}", 400, status='error', details="Ensure all required keys are provided."), 400
    except ValueError as e:
        logging.error("Invalid data or operation", exc_info=True)
        return create_response(str(e), 400, status='error'), 400
    except Exception as e:
        logging.error("Internal server error", exc_info=True)
        return create_response("Internal server error", 500, status='error'), 500

@vms.route('/<vm_sid>', methods=['DELETE'])
def delete_vm(vm_sid):
    try:
        # Brute Force Cluster. Need Improvement
        hcl_config = load_hcl_config(get_config_path())
        other_node_url = "http://10.11.1.182:6969/v1/vms"  # Replace with the URL of your other node
        
        if hcl_config["vm-" + vm_sid]["node"] != 'pve':
            response = requests.delete(f"{other_node_url}/{vm_sid}")
            return response.content, response.status_code
        else:
            delete_vm_config(vm_sid)
            handle_request({"action": "delete", "sid": vm_sid})
            return create_response('VM configuration on PVE1 deleted successfully. Deleting VM in PVE1', 200), 200

    except KeyError as e:
        logging.error(f"No VM with SID found. SID: {vm_sid}", exc_info=True)
        return create_response(f"No VM with SID {vm_sid} found", 404, status='error'), 404
    except Exception as e:
        logging.error("Internal server error during deletion", exc_info=True)
        return create_response("Internal server error", 500, status='error'), 500

@vms.route('/templates', methods=['GET'])
def check_vm_template():
    try:
        command = 'pvesh get /pools/Templates --output-format json | jq -r \'.members[] | select(.id | startswith("qemu")) | {id: (.id | split("/")[1]), name: .name}\''
        output = subprocess.check_output(command, shell=True)
        output = output.decode('utf-8')  # decode bytes to string

        # Split the output into lines
        lines = output.splitlines()

        # Group the lines into separate JSON objects
        json_objects = []
        json_object = []
        for line in lines:
            json_object.append(line)
            if line.strip() == '}':
                json_objects.append('\n'.join(json_object))
                json_object = []

        # Parse each JSON object separately and add it to a dictionary
        output = {json.loads(json_object)['name']: json.loads(json_object)['id'] for json_object in json_objects}

        # Call function to update tfvars file
        update_tfvars(output)

        # Check if output is empty
        if not output:
            return create_response('No VM templates found', 200, details='No VM templates exist'), 200

        # Return only the names of the VM templates
        return create_response('VM templates retrieved successfully', 200, details=list(output.keys())), 200
    except Exception as e:
        logging.error("Internal server error during template retrieval", exc_info=True)
        return create_response("Internal server error", 500, status='error'), 500