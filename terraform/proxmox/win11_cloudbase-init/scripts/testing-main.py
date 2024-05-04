from user_vm_config import add_vm_config, delete_vm_config, update_pci_data, validate_and_fill_defaults
import subprocess
import json

def test_create_vm():
    try:
        # Updated hardcoded VM configuration for testing
        vm_config = {
            "vm-SIDtest": {
                "name": "VM-CloudGaming-SIDtest",
                "desc": "VM-CloudGaming-SIDtest",
                "cpu_type": "host",
                "memory": 8192,
                "clone": "101-No-PCI",
                "dns": "",
                "ip": "",
                "gateway": "",
                "pci_device": "GeForce RTX 4070 Ti",
                "SID": "SIDtest"
            }
        }
        for key, value in vm_config.items():
            print(f'Type of value before validate_and_fill_defaults: {type(value)}')
            print(f'Value before validate_and_fill_defaults: {value}')
            value = validate_and_fill_defaults(value)
            print(f'Type of value before update_pci_data: {type(value)}')
            print(f'Value before update_pci_data: {value}')
            vm_config[key] = update_pci_data({key: value})[key]
        add_vm_config(vm_config)
        print('VM configuration added successfully')
    except Exception as e:
        print(f'Error: {str(e)}')

def test_delete_vm():
    try:
        # Hardcoded VM identifier for testing
        vm_id = "vm-SIDtest"
        delete_vm_config(vm_id)
        print('VM configuration deleted successfully')
    except Exception as e:
        print(f'Error: {str(e)}')


def update_tfvars(output):
    # Create a dictionary where the keys are the 'name' values and the values are the 'id' values
    vm_template_id = {name: int(id) for name, id in output.items()}

    # Read existing tfvars content
    with open('win11_cloudbase-init2.auto.tfvars', 'r') as f:
        tfvars_content = f.readlines()

    # Find the start and end lines of the vm_template_id section
    start_line = next(i for i, line in enumerate(tfvars_content) if line.strip().startswith('vm_template_id = {')) + 1
    end_line = next((i for i, line in enumerate(tfvars_content[start_line:]) if line.strip() == '}'), len(tfvars_content)) + start_line

    # Remove the old vm_template_id section, including the closing brace
    del tfvars_content[start_line:end_line+1]

    # Insert the new vm_template_id section
    for name, vm_id in vm_template_id.items():
        tfvars_content.insert(start_line, f'  "{name}" = {vm_id},\n')
    tfvars_content.insert(start_line + len(vm_template_id), '}\n')

    # Write updated content back to tfvars file
    with open('win11_cloudbase-init2.auto.tfvars', 'w') as f:
        f.writelines(tfvars_content)

def test_check_vm_template():
    try:
        command = 'pvesh get /pools/Templates --output-format json | jq -r \'.members[] | select(.id | startswith("qemu")) | {id: (.id | split("/")[1]), name: .name}\''
        output = subprocess.check_output(command, shell=True)
        output = output.decode('utf-8')  # decode bytes to string
        print(f'Raw Output: {output}')  # Print raw output for debugging
                
        # Format the output as JSON array
        json_output = '[{}]'.format(', '.join(output.splitlines()))
        print(f'Formatted Output: {json_output}')  # Print formatted output for debugging

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

        print(f'Parsed Output: {output}')  # Print parsed output for debugging

        # Call function to update tfvars file
        update_tfvars(output)

    except Exception as e:
        print(str(e))


if __name__ == '__main__':
    # test_create_vm()
    test_delete_vm()
    # test_check_vm_template()
    # test()