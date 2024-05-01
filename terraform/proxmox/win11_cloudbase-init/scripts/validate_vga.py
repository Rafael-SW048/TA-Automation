import subprocess
import re

def get_vga_info():
    """
    This function retrieves information about VGA compatible controllers using the 'lspci' command.

    Returns:
        list: A list of dictionaries containing information about each VGA compatible controller.
              Each dictionary has two keys:
                  - 'id': The PCI ID of the VGA compatible controller.
                  - 'type': The type of the VGA compatible controller.
    """
    lspci_output = subprocess.check_output("lspci | grep VGA", shell=True).decode('utf-8')
    vga_lines = lspci_output.strip().split('\n')

    vga_info = {}
    for line in vga_lines:
        match = re.search(r'(\d+:\d+\.\d+) VGA compatible controller: (.+)', line)
        if match:
            pci_id = match.group(1)
            # Add leading zeros and colon if they don't exist
            if len(pci_id.split(":")[0]) < 4:
                pci_id = "0000:" + pci_id
            vga_info[pci_id] = match.group(2)
    return vga_info

def get_vm_pci_devices(vm_id):
    """
    This function retrieves the PCI devices assigned to a specific VM by ID.

    Args:
        vm_id (int): The ID of the virtual machine.

    Returns:
        list: A list of formatted PCI device IDs.
    """
    pci_devices = []
    # Use qm config to get VM configuration
    cmd = f"qm config {vm_id}"
    output = subprocess.check_output(cmd, shell=True).decode("utf-8")

    # Search for lines with "hostpci" keyword
    for line in output.splitlines():
        if "hostpci" in line:
            # Extract information using regular expression
            match = re.search(r"hostpci\d*: ([\w:.]+)", line)
            if match:
                pci_device = match.group(1)
                # Standardize the format of PCI IDs
                if not re.search(r"\.\d+$", pci_device):
                    pci_device += ".0"
                pci_devices.append(pci_device)

    return pci_devices



def get_all_vm_pci_devices():
  """
  This function iterates through all VMs and retrieves their assigned PCI devices.

  Returns:
      dict: A dictionary where keys are VM IDs and values are lists of assigned PCI device IDs.
  """
  vm_pci_devices = {}
  # Get a list of all VM IDs
  vm_ids = subprocess.check_output("qm list", shell=True).decode("utf-8").splitlines()
  # Remove header line
  vm_ids.pop(0)
  
  for vm_id in vm_ids:
    vm_id = int(vm_id.split()[0])  # Extract VM ID from line
    vm_pci_devices[vm_id] = get_vm_pci_devices(vm_id)

  return vm_pci_devices

def assign_pci_to_vm(vga_type="GeForce RTX 4070 Ti"):
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
    matching_pci_ids = [pci_id for pci_id, vga in existing_vga_info.items() if vga_pattern.search(vga)]

    # If no matching PCI VGA devices found, raise an error
    if not matching_pci_ids:
        raise ValueError(f"No PCI VGA devices found matching the type '{vga_type}'.")

    # Get information about all VM assigned PCI devices
    vm_pci_devices = get_all_vm_pci_devices()

    # Filter out used and available PCI IDs for the specified VGA type
    used_pci_ids = {}
    for vm_id, pci_ids in vm_pci_devices.items():
        for pci_id in pci_ids:
            if pci_id in matching_pci_ids:
                used_pci_ids.setdefault(pci_id, []).append(vm_id)

    available_pci_ids = [pci_id for pci_id in matching_pci_ids if pci_id not in used_pci_ids]
    print(available_pci_ids, used_pci_ids)

    return available_pci_ids, used_pci_ids

if __name__ == "__main__":
    try:
        # Get available and used PCI IDs for the specified VGA type
        available_pci_ids, used_pci_ids = assign_pci_to_vm("GeForce RTX 4070 Ti")

        # Process available and used PCI IDs
        if available_pci_ids:
            print("Available PCI IDs for assignment:")
            for pci_id in available_pci_ids:
                print(pci_id)
        else:
            print("All PCI IDs for the specified VGA type are already used.")

        if used_pci_ids:
            print("\nUsed PCI IDs:")
            for pci_id, vm_ids in used_pci_ids.items():
                print(f"PCI ID: {pci_id}, Used by VMs: {vm_ids}")
    except ValueError as e:
        print(e)  # Print the error message
        # Handle the exception gracefully, e.g., by displaying a message or taking alternative actions
