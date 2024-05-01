import hcl
import os
from validate_vga import assign_pci_to_vm  # Import the assign_pci_to_vm function from VGA.py

def update_pci_data(json_data):
    for vm_id, vm_info in json_data.items():
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
                print(f"Error while assigning PCI device for {vm_id}: {e}")
                # Handle the error gracefully, e.g., by logging or taking alternative actions


def add_vm_config(vm_config):
  try:
    # Get the directory of the script
    dir_path = os.path.dirname(os.path.realpath(__file__))

    # Go up one directory
    parent_dir = os.path.dirname(dir_path)

    # Construct the path to the vms_config.auto.tfvars file
    config_path = os.path.join(parent_dir, 'vms_config.auto.tfvars')

    # Load the existing configurations
    with open(config_path, 'r') as f:
        data = hcl.load(f)

    # Check if a configuration with the given identifier already exists
    if list(vm_config.keys())[0] in data['vms_config']:
      raise ValueError(f"VM configuration for {list(vm_config.keys())[0]} already exists")

    update_pci_data(vm_config)

    # Add the new configuration
    data['vms_config'].update(vm_config)

    # Write the updated configurations back to the file
    with open(config_path, 'w') as f:
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
  except Exception as e:
    print(f"Error while adding VM configuration: {str(e)}")
    raise

def delete_vm_config(vm_id):
  try:
    # Get the directory of the script
    dir_path = os.path.dirname(os.path.realpath(__file__))

    # Go up one directory
    parent_dir = os.path.dirname(dir_path)

    # Construct the path to the vms_config.auto.tfvars file
    config_path = os.path.join(parent_dir, 'vms_config.auto.tfvars')


    # Load the existing configurations
    with open(config_path, 'r') as f:
      data = hcl.load(f)

    # Check if a configuration with the given identifier exists
    if vm_id not in data['vms_config']:
      raise ValueError(f"No VM configuration found for {vm_id}")

    # Delete the specified configuration
    del data['vms_config'][vm_id]

    # Write the updated configurations back to the file
    with open(config_path, 'w') as f:
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
  except Exception as e:
    print(f"Error while deleting VM configuration: {str(e)}")
    raise