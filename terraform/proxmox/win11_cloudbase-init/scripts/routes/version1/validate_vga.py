import logging
import re
from routes.version1.helpers import runRemote
  
def get_vga_info():
  """
  This function retrieves information about VGA compatible controllers using the 'lspci' command.

  Returns:
      list: A list of dictionaries containing information about each VGA compatible controller.
            Each dictionary has two keys:
                - 'id': The PCI ID of the VGA compatible controller.
                - 'type': The type of the VGA compatible controller.
  """
  lspci_output = runRemote('lspci | grep VGA', runOnAllNodes=True)
  vga_lines = lspci_output.strip().split('\n')

  vga_info = {}
  current_ip = ''
  for line in vga_lines:
    ip_match = re.search(r'(\d+\.\d+\.\d+\.\d+):', line)
    if ip_match:
      current_ip = ip_match.group(1)
      vga_info[current_ip] = {}
    else:
      vga_match = re.search(r'(\d+:\d+\.\d+) VGA compatible controller: (.+)', line)
      if vga_match:
        pci_id = vga_match.group(1)
        if len(pci_id.split(":")[0]) < 4:
          pci_id = "0000:" + pci_id
        vga_info[current_ip][pci_id] = vga_match.group(2)

  return vga_info

def get_vm_pci_devices(vm_id):
    """
    This function retrieves the PCI devices assigned to a specific VM by ID.

    Args:
        vm_id (int): The ID of the virtual machine.

    Returns:
        list: A list of formatted PCI device IDs.
    """
    # Determine the node based on the initial digit of the VM ID
    initial_digit = int(str(vm_id)[0])
    if initial_digit in [1, 2, 5, 6]:
      node = '10.11.1.181'
    elif initial_digit in [3, 4, 7, 8]:
      node = '10.11.1.182'
    else:
      raise ValueError(f"Invalid VM ID {vm_id}. VM ID is wrong or it is not managed by this system.")

    cmd = f"qm config {vm_id}"
    output = runRemote(cmd, node)  # Run the command on the correct node

    pci_devices = []
    for line in output.splitlines():
      if "hostpci" in line:
        match = re.search(r"hostpci\d*: ([\w:.]+)", line)
        if match:
          pci_device = match.group(1)
          if not re.search(r"\.\d+$", pci_device):
            pci_device += ".0"
          pci_devices.append(pci_device)
    return pci_devices

def get_all_vm_pci_devices(nodeIps=[]):
    """
    This function iterates through all VMs and retrieves their assigned PCI devices.

    Returns:
        dict: A dictionary where keys are node IPs and values are dictionaries with 'running' and 'stopped' as keys and dictionaries with VM IDs and PCI device IDs as values.
    """
    all_vm_pci_devices = {}
    if not nodeIps:
      output_lines = runRemote("qm list", runOnAllNodes=True).splitlines()
    else:
      for nodeIp in nodeIps:
        output_lines = runRemote("qm list", nodeIp).splitlines()
    current_node = ''

    for line in output_lines:
        stripped_line = line.strip()
        if stripped_line.startswith('Run on:'):
            current_node = stripped_line.split(':')[1].strip()  # Extract the node information
            all_vm_pci_devices[current_node] = {'running': {}, 'stopped': {}}  # Initialize new dictionaries for the current node
            continue
        if stripped_line.startswith('VMID') or not stripped_line:
            continue  # Skip the header line and any empty line

        line_parts = stripped_line.split()
        vm_id = int(line_parts[0])
        status = line_parts[2]
        pci_id = get_vm_pci_devices(vm_id)
        pci_id = pci_id[0] if pci_id else ''  # Convert the PCI ID to a string

        all_vm_pci_devices[current_node][status][vm_id] = pci_id

    return all_vm_pci_devices
  
def assign_pci_to_vm(vga_type="GeForce RTX 4070 Ti"):
# def assign_pci_to_vm(vga_type="GeForce GTX 1080"):
  """
  Assigns PCI devices to VMs based on the specified VGA type.

  Args:
    vga_type (str): The type of VGA compatible controller. Defaults to "GeForce RTX 4070 Ti" if not provided.

  Returns:
    tuple: A tuple containing two dictionaries:
      - The first dictionary has keys as VM IDs and values as lists of available PCI device IDs.
      - The second dictionary has keys as VM IDs and values as lists of used PCI device IDs.
  """
  # Get existing VGA info
  existing_vga_info = get_vga_info()

  # Define a regular expression pattern for the VGA type
  vga_pattern = re.compile(re.escape(vga_type), re.IGNORECASE)

  # Find PCI IDs for the specified VGA type
  # matching_pci_ids = [(nodeip, pciId) for nodeip, vgaDict in existing_vga_info.items() for pciId, vga in vgaDict.items() if vga_pattern.search(vga)]
  matching_pci_ids = {nodeIp: [pciId for pciId, vgaName in vgaDict.items() if vga_pattern.search(vgaName)] for nodeIp, vgaDict in existing_vga_info.items()}
  # Filter out empty lists
  matching_pci_ids = {nodeIp: pciIds for nodeIp, pciIds in matching_pci_ids.items() if pciIds}

  # If no matching PCI VGA devices found, raise an error
  print(matching_pci_ids)
  if not any(matching_pci_ids.values()):
      raise ValueError(f"No PCI VGA devices found matching the type '{vga_type}'.")

  # Get information about all VM assigned PCI devices
  nodeIps = list(matching_pci_ids.keys())
  vm_pci_devices = get_all_vm_pci_devices(nodeIps)

  # Filter out used and available PCI IDs for the specified VGA type
  result = {}
  for nodeIp, pci_ids in matching_pci_ids.items():
    # used_pci_ids = [pci_id for pci_id in pci_ids if pci_id in vm_pci_devices[nodeIp]['running'].values() or pci_id in vm_pci_devices[nodeIp]['stopped'].values()]
    used_pci_ids = [pci_id for pci_id in pci_ids if pci_id in vm_pci_devices[nodeIp]['running'].values()]
    available_pci_ids = [pci_id for pci_id in pci_ids if pci_id not in used_pci_ids]
    result[nodeIp] = {'available': available_pci_ids, 'used': used_pci_ids}

  return result
