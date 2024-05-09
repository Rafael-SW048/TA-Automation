import hcl
import os
from routes.version1.validate_vga import assign_pci_to_vm  # Import the assign_pci_to_vm function from VGA.py

def update_pci_data(json_data):
    for vm_sid, vm_info in json_data.items():
        pci_device = vm_info.get('pci_device')
        if pci_device:
            try:
                available_pci_ids, _ = assign_pci_to_vm(pci_device)
                if available_pci_ids:
                    # If available PCI IDs exist, update the JSON data with one of them
                    vm_info['pci_device'] = available_pci_ids[0]
                else:
                    # If no available PCI IDs, empty out the PCI device data
                    vm_info['pci_device'] = ""
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
        "clone": "Win11x64-VM-template-cloudbaseInit-raw-NoSysPrep",
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

    return vm_config

def load_hcl_config(path):
    with open(path, 'r') as f:
        return hcl.load(f)

def save_hcl_config(data, path):
    with open(path, 'w') as f:
        f.write('vms_config = {\n')
        for vm, config in data['vms_config'].items():
            f.write(f'  {vm} = {{\n')
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

      if vm_sid not in data['vms_config']:
          raise ValueError(f"No VM configuration found for {vm_sid}")
      
      del data['vms_config'][vm_sid]
      save_hcl_config(data, config_path)
  except Exception as e:
    print(f"Error while deleting VM configuration: {str(e)}")
    raise

def update_tfvars(vm_templates):
    # Create a dictionary where the keys are the 'name' values and the values are the 'id' values
    vm_template_id = {name: int(id) for name, id in vm_templates.items()}

    # Read existing tfvars content
    with open('../win11_cloudbase-init.auto.tfvars', 'r') as f:
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
    with open('../win11_cloudbase-init.auto.tfvars', 'w') as f:
        f.writelines(tfvars_content)