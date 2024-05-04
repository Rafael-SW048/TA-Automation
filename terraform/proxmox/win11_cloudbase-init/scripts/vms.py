from flask import Flask, request, jsonify, Blueprint
import subprocess, json
import logging
from user_vm_config import add_vm_config, delete_vm_config, update_pci_data, validate_and_fill_defaults, update_tfvars
from run_vm_creation import update_terraform_state


vms = Blueprint('vms', __name__, url_prefix='/vms')

def create_error_response(message, code, details=None):
    response = {"error": {"code": code, "message": message}}
    if details:
        response["error"]["details"] = details
    return jsonify(response)

app = Flask(__name__)
@vms.route('/', methods=['POST'])
def create_vm():
    try:
        vm_config = request.get_json()
        if not vm_config:
            raise ValueError("Request data is not JSON")
        validated_config = {key: validate_and_fill_defaults(value) for key, value in vm_config.items()}
        pci_updated_config = {key: update_pci_data(value) for key, value in validated_config.items()}
        add_vm_config(pci_updated_config)
        update_tfvars(pci_updated_config)
        return jsonify({'message': 'VM configuration added successfully'}), 200
    except KeyError as e:
        logging.error("Missing key in VM configuration", exc_info=True)
        return create_error_response(f"Missing key in VM configuration: {str(e)}", "missing_key", "Ensure all required keys are provided."), 400
    except ValueError as e:
        logging.error("Invalid data or operation", exc_info=True)
        return create_error_response(str(e), "invalid_data"), 400
    except Exception as e:
        logging.error("Internal server error", exc_info=True)
        return create_error_response("Internal server error", "server_error"), 500

@vms.route('/<vm_sid>', methods=['DELETE'])
def delete_vm(vm_sid):
    try:
        delete_vm_config(vm_sid)
        update_tfvars({})
        return jsonify({'message': 'VM configuration deleted successfully'}), 200
    except KeyError as e:
        logging.error("No VM with SID found", exc_info=True)
        return create_error_response(f"No VM with SID {vm_sid} found", "not_found"), 404
    except Exception as e:
        logging.error("Internal server error during deletion", exc_info=True)
        return create_error_response("Internal server error", "server_error"), 500
    
@vms.route('/templates', methods=['GET'])
def check_vm_template():
    try:
        command = 'pvesh get /pools/Templates --output-format json | jq -r \'.members[] | select(.id | startswith("qemu")) | {id: (.id | split("/")[1]), name: .name}\''
        output = subprocess.check_output(command, shell=True)
        output = output.decode('utf-8')  # decode bytes to string

        # Format the output as JSON array
        json_output = '[{}]'.format(', '.join(output.splitlines()))

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

        # Call function to update tfvars file
        update_tfvars(output)

        # Parse each JSON object separately and add it to a dictionary
        output = {json.loads(json_object)['name']: json.loads(json_object)['id'] for json_object in json_objects}

        # Return only the names of the VM templates
        return jsonify(list(output.keys())), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500