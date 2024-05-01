from user_vm_config import add_vm_config, delete_vm_config
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

def test_create_vm():
    try:
        # Updated hardcoded VM configuration for testing
        vm_config = {
            "vm-SIDtest": {
                "name": "VM-CloudGaming-SIDtest",
                "desc": "VM-CloudGaming-SIDtest",
                "cores": 6,
                "cpu_type": "host",
                "memory": 8192,
                # "clone": "Win11x64-VM-template-cloudbaseInit-raw-NoSysPrep",
                "clone": "VM 101",
                "dns": "",
                "ip": "",
                "gateway": "",
                "pci_device": "GeForce RTX 4070 Ti",
                "SID": "SIDtest"
            }
        }
        update_pci_data(vm_config)
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

if __name__ == '__main__':
    test_create_vm()
    # test_delete_vm()