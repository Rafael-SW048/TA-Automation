import hcl
import os
from routes.version1.validate_vga import assign_pci_to_vm  # Import the assign_pci_to_vm function from VGA.py
from routes.version1.helpers import runRemote

def update_pci_data(json_data):
    nodes = {'pve': '10.11.1.181', 'pve2': '10.11.1.182'}  # Unique keys for nodes
    nodesName = list(nodes.keys())

    for vm_sid, vm_info in json_data.items():
        pci_device = vm_info.get('pci_device')
        if pci_device:
            print(f"PCI device specified for {vm_sid}")
            try:
                print(f"Getting PCI device for {vm_sid}")
                pci_data = assign_pci_to_vm(pci_device)  # Retrieve PCI data for each VM
                nodeIps = list(pci_data.keys())
                updated = False
                for nodeIp in nodeIps:
                    if pci_data[nodeIp]['available']:
                        print(f"Available PCI devices for {vm_sid}: {pci_data[nodeIp]['available']}")
                        for nodeName in nodesName:
                            print(nodes, nodeName, nodeIps, nodeIp)
                            print("Status: ", nodes[nodeName] in nodeIps)
                            if nodes[nodeName] in nodeIps:
                                print(f"Node {nodeName} has available PCI devices")
                                vm_info['pci_device'] = pci_data[nodeIp]['available'][0]
                                vm_info['node'] = nodeName
                                updated = True
                                break
                        if updated:
                            break  # Break out of both loops if updated
                    else:
                        print(f"No available PCI devices for {vm_sid} on {nodeIp}")
                        vm_info["clone"] = "RTX-4070-Ti-sysprep-updated"
                        vm_info['pci_device'] = ""
                        vm_info['node'] = "pve"
                
            except ValueError as e:
                print(f"Error while assigning PCI device for {vm_sid}: {e}")
                # Handle the error gracefully, e.g., by logging or taking alternative actions
                            
        else:
            print(f"No PCI device specified for {vm_sid}")
            if vm_info['clone'] == "GTX-1080":
                vm_info['pci_device'] = ""
                vm_info['node'] = "pve"
            else:
                vm_info['pci_device'] = ""
                vm_info['node'] = "pve"
                        
                
    return json_data

def pc_settings(vm_config):
    pci_device_settings = {
        "GeForce RTX 4070 Ti": {"disk_size": 512, "clone": "RTX-4070-Ti-sysprep-updated", "node": "pve", "cores": 6},
        "GeForce GTX 1080": {"disk_size": 200, "clone": "GTX-1080-updated", "node": "pve2", "cores": 4}
    }
    
    clone_settings = {
        "RTX-4070-Ti-sysprep-updated": {"disk_size": 512, "node": "pve", "pci_device": "", "cores": 6},
        "GTX-1080-updated": {"disk_size": 200, "node": "pve2", "pci_device": "", "cores": 4}
    }
    
    if 'pci_device' in vm_config and vm_config['pci_device'] in pci_device_settings:
        return pci_device_settings[vm_config['pci_device']]
    elif 'clone' in vm_config and vm_config['clone'] in clone_settings:
        return clone_settings[vm_config['clone']]
    else:
        return None  # No specific settings found

def validate_and_fill_defaults(vm_config):
    required_keys = ["name", "desc", "SID"]
    optional_keys_with_defaults = {
        "cores": 6,
        "cpu_type": "host",
        "memory": 8192,
        "node": "pve",
        "clone": "RTX-4070-Ti-sysprep-updated",
        "disk_size": 512,
        "dns": "",
        "ip": "",
        "gateway": "",
        "pci_device": "GeForce RTX 4070 Ti"
    }
    
    # Get specific settings based on pci_device or clone
    specific_settings = pc_settings(vm_config)
    if specific_settings:
        vm_config.update(specific_settings)
    else:
        vm_config.update(optional_keys_with_defaults)
    
    # Validate required keys and set default values
    for key in required_keys:
        if key not in vm_config:
            raise ValueError(f'Missing key: {key}')
    
    for key, default_value in optional_keys_with_defaults.items():
        if key not in vm_config:
            vm_config[key] = default_value
        elif key in ["cores", "memory"] and not isinstance(vm_config[key], int):
            raise ValueError(f'Invalid type for key: {key}, expected integer')
        elif key in ["cpu_type", "clone", "dns", "ip", "gateway", "pci_device"] and not isinstance(vm_config[key], str):
            raise ValueError(f'Invalid type for key: {key}, expected string')

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