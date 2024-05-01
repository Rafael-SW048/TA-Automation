from flask import Flask, request, jsonify
from user_vm_config import add_vm_config, delete_vm_config

app = Flask(__name__)

@app.route('/vm', methods=['POST'])
def create_vm():
    try:
        vm_config = request.get_json()
        add_vm_config(vm_config)
        return jsonify({'message': 'VM configuration added successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/vm/<vm_id>', methods=['DELETE'])
def delete_vm(vm_id):
    try:
        delete_vm_config(vm_id)
        return jsonify({'message': 'VM configuration deleted successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)