from flask import Flask, request, jsonify, Blueprint
import subprocess, json
import logging
from routes.version1.user_vm_config import validate_and_fill_defaults, update_pci_data, add_vm_config, delete_vm_config, update_tfvars


vms = Blueprint('vms', __name__, url_prefix='/vms')

def create_response(message, code, status='success', details=None):
    response = {status: {"code": code, "message": message}}
    if details:
        response[status]["details"] = details
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
        return create_response('VM configuration added successfully', 200), 200
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
        delete_vm_config(vm_sid)
        update_tfvars({})
        return create_response('VM configuration deleted successfully', 200), 200
    except KeyError as e:
        logging.error("No VM with SID found", exc_info=True)
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
        print(output)
        # update_tfvars(output)

        # Parse each JSON object separately and add it to a dictionary
        output = {}
        for json_object in json_objects:
            try:
                parsed_object = json.loads(json_object)
                output[parsed_object['name']] = parsed_object['id']
            except json.JSONDecodeError:
                logging.error(f"Failed to parse JSON object: {json_object}")
            except KeyError:
                logging.error(f"JSON object does not have 'name' or 'id' field: {json_object}")

        # Return only the names of the VM templates
        return create_response('VM templates retrieved successfully', 200, details=list(output.keys())), 200
    except Exception as e:
        logging.error("Internal server error during template retrieval", exc_info=True)
        return create_response("Internal server error", 500, status='error'), 500