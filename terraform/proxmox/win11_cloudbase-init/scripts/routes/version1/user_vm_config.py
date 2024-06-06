import hcl
import os
from routes.version1.validate_vga import assign_pci_to_vm  # Import the assign_pci_to_vm function from VGA.py
from routes.version1.helpers import runRemote

def getNodesName():
    command = "pvesh get /nodes --output-format json-pretty | jq -r '.[].node'"
    node_names_output = runRemote(command)
    node_names = node_names_output.split('\n')
    node_names = [name for name in node_names if name]  # remove empty strings
    node_names = node_names[1:]
    return node_names
  
import json

def getNodesMemory(node_name):
    command = f"pvesh get /nodes/{node_name}/status --output-format json-pretty | jq -r '.memory'"
    memory_output = runRemote(command)
    memory_output = memory_output.split('{', 1)[-1]  # ignore any lines before the JSON data
    memory_output = '{' + memory_output  # add the opening brace back to the start of the JSON data
    memory_data = json.loads(memory_output)
    return memory_data
  
def getNodesLoad():
    nodes_name = getNodesName()
    nodes_load = {}
    print(nodes_name)
    for node_name in nodes_name:
        nodes_load[node_name] = getNodesMemory(node_name)
    print(nodes_load)
    return nodes_load

def update_pci_data(json_data):
    nodes = {'pve': '10.11.1.181', 'pve2': '10.11.1.182'}  # Unique keys for nodes
    nodesLoad = getNodesLoad()  # Retrieve node load information once outside the loop
    sortedNodeLoad = sorted(nodesLoad, key=lambda k: nodesLoad[k]['free'])  # Sort once
    
    for vm_sid, vm_info in json_data.items():
        pci_device = vm_info.get('pci_device')
        if pci_device:
            try:
                pci_data = assign_pci_to_vm(pci_device)  # Retrieve PCI data for each VM
                nodeIps = pci_data.keys()
                updated = False
                for nodeIp in nodeIps:
                    if pci_data[nodeIp]['available']:
                        for nodeName in sortedNodeLoad:
                            print(nodes, nodeName, nodeIps, nodeIp)
                            if nodes[nodeName] in nodeIps:
                                vm_info['pci_device'] = pci_data[nodeIp]['available'][0]
                                vm_info['node'] = nodeName
                                updated = True
                                break
                        if updated:
                            break  # Break out of both loops if updated
                else:
                    print("here7")
                    vm_info['pci_device'] = ""
                    vm_info['node'] = "pve"
                        
            except ValueError as e:
                print(f"Error while assigning PCI device for {vm_sid}: {e}")
                # Handle the error gracefully, e.g., by logging or taking alternative actions
                
    return json_data

def validate_and_fill_defaults(vm_config):
    required_keys = ["name", "desc", "SID"]
    optional_keys_with_defaults = {
        "cores": 6,
        "cpu_type": "host",
        "memory": 8192,
        "node": "pve",
        # "clone": "RTX-4070-Ti-sysprep-On-ChangeScript",
        "clone": "RTX-4070-Ti-sysprep-On",
        # "clone": "RTX-4070-Ti-sysprep",
        "disk_size": 200,
        "dns": "",
        "ip": "",
        "gateway": "",
        "pci_device": "GeForce RTX 4070 Ti"
    }

    for key in required_keys:
        if key not in vm_config:
            raise ValueError(f'Missing key: {key}')
        if not isinstance(vm_config[key], str):
            raise ValueError(f'Invalid type for key: {key}, expected string')

    for key, default_value in optional_keys_with_defaults.items():
        if key not in vm_config:
            vm_config[key] = default_value
        elif key in ["cores", "memory"] and not isinstance(vm_config[key], int):
            raise ValueError(f'Invalid type for key: {key}, expected integer')
        elif key in ["cpu_type", "clone", "dns", "ip", "gateway", "pci_device"] and not isinstance(vm_config[key], str):
            raise ValueError(f'Invalid type for key: {key}, expected string')
    
    # Set specific values for 'clone' and 'node' based on 'pci_device'
    if 'pci_device' in vm_config:
        if vm_config['pci_device'] == 'GeForce RTX 4070 Ti':
            # vm_config['clone'] = "RTX-4070-Ti-sysprep-On-ChangeScript"
            vm_config['clone'] = 'RTX-4070-Ti-sysprep-On'
            vm_config['disk_size'] = 512
            # vm_config['clone'] = 'RTX-4070-Ti-sysprep'
            vm_config['node'] = 'pve'
        elif vm_config['pci_device'] == 'GeForce GTX 1080':
            vm_config['clone'] = 'GTX-1080-pve2-fixed' # Need to update this value
            vm_config['disk_size'] = 200
            vm_config['node'] = 'pve2'
    else:
        vm_config['node'] = 'pve'


    return vm_config

def load_hcl_config(path):
    with open(path, 'r') as f:
        return hcl.load(f)

def save_hcl_config(data, path):
    with open(path, 'w') as f:
        f.write('vms_config = {\n')
        for vm, config in data['vms_config'].items():
            f.write(f'  "{vm}" = {{\n')
            for key, value in config.items():
                if isinstance(value, str):
                    f.write(f'    {key} = "{value}"\n')
                else:
                    f.write(f'    {key} = {value}\n')
            f.write('  }\n')
        f.write('}\n')

def get_config_path():
    dir_path = os.path.dirname(os.path.realpath(__file__))
    parent_dir = os.path.dirname(os.path.dirname(os.path.dirname(dir_path)))
    return os.path.join(parent_dir, 'vms_config.auto.tfvars')

def add_vm_config(vm_config):
  try:
    config_path = get_config_path()
    data = load_hcl_config(config_path)
    
    vm_id = list(vm_config.keys())[0]
    if vm_id in data['vms_config']:
        raise ValueError(f"VM configuration for {vm_id} already exists")
    
    update_pci_data(vm_config)
    data['vms_config'].update(vm_config)
    save_hcl_config(data, config_path)
  except Exception as e:
    print(f"Error while adding VM configuration: {str(e)}")
    raise

def delete_vm_config(vm_sid):
  try:
      config_path = get_config_path()
      data = load_hcl_config(config_path)

      vm_key = f"vm-{vm_sid}"
      if vm_key not in data['vms_config']:
          print(data['vms_config'])
          raise ValueError(f"No VM configuration found for {vm_sid}")
      
      del data['vms_config'][vm_key]
      save_hcl_config(data, config_path)
  except Exception as e:
    print(f"Error while deleting VM configuration: {str(e)}")
    raise

def update_tfvars(vm_templates):
    # Create a dictionary where the keys are the 'name' values and the values are the 'id' values
    print(vm_templates)
    vm_template_id = {name: int(id) for name, id in vm_templates.items()}

    # Read existing tfvars content
    with open('win11_cloudbase-init.auto.tfvars', 'r') as f:
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
    with open('win11_cloudbase-init.auto.tfvars', 'w') as f:
        f.writelines(tfvars_content)