import hcl2
import os
import logging
from routes.version1.validate_vga import assign_pci_to_vm
from routes.version1.helpers import runRemote
from routes.version1.config import Config

logger = logging.getLogger(__name__)

def update_pci_data(json_data):
    nodes = {node['name']: node['url'].split('http://')[1].split(':')[0] for node in Config.SECONDARY_NODES}
    nodes[Config.PRIMARY_NODE['name']] = Config.PRIMARY_NODE['url'].split('http://')[1].split(':')[0]
    nodeName = list(nodes.keys())
    
    for vm_sid, vm_info in json_data.items():
        pci_device = vm_info.get('pci_device')
        if pci_device:
            logger.info(f"PCI device specified for {vm_sid}")
            try:
                logger.info(f"Getting PCI device for {vm_sid}")
                pci_data = assign_pci_to_vm(pci_device)
                nodeIps = list(pci_data.keys())
                updated = False
                for nodeIp in nodeIps:
                    if pci_data[nodeIp]['available']:
                        logger.info(f"Available PCI devices for {vm_sid}: {pci_data[nodeIp]['available']}")
                        for nodeName in nodes:
                            if nodes[nodeName] in nodeIps:
                                logger.info(f"Node {nodeName} has available PCI devices")
                                vm_info['pci_device'] = pci_data[nodeIp]['available'][0]
                                vm_info['node'] = nodeName
                                updated = True
                                break
                        if updated:
                            break
                    else:
                        logger.info(f"No available PCI devices for {vm_sid} on {nodeIp}")
                        vm_info["clone"] = "RTX-4070-Ti-sysprep-updated"
                        vm_info['pci_device'] = ""
                        vm_info['node'] = Config.PRIMARY_NODE['name']
                
            except ValueError as e:
                logger.error(f"Error while assigning PCI device for {vm_sid}: {e}")
                            
        else:
            logger.info(f"No PCI device specified for {vm_sid}")
            if vm_info['clone'] == "GTX-1080":
                vm_info['pci_device'] = ""
                vm_info['node'] = Config.PRIMARY_NODE['name']
            else:
                vm_info['pci_device'] = ""
                vm_info['node'] = Config.PRIMARY_NODE['name']
                        
    return json_data

def pc_settings(vm_config):
    pci_device_settings = {
        "GeForce RTX 4070 Ti": {"disk_size": 512, "clone": "RTX-4070-Ti-sysprep-updated", "node": Config.PRIMARY_NODE['name'], "cores": 6},
        "GeForce GTX 1080": {"disk_size": 200, "clone": "GTX-1080-updated", "node": Config.SECONDARY_NODES[0]['name'], "cores": 4}
    }
    
    clone_settings = {
        "RTX-4070-Ti-sysprep-updated": {"disk_size": 512, "node": Config.PRIMARY_NODE['name'], "pci_device": "", "cores": 6},
        "GTX-1080-updated": {"disk_size": 200, "node": Config.SECONDARY_NODES[0]['name'], "pci_device": "", "cores": 4}
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
        "node": Config.PRIMARY_NODE['name'],
        "clone": "RTX-4070-Ti-sysprep-updated",
        "disk_size": 512,
        "dns": "",
        "ip": "",
        "gateway": "",
        "pci_device": "GeForce RTX 4070 Ti"
    }
    
    specific_settings = pc_settings(vm_config)
    if specific_settings:
        vm_config.update(specific_settings)
    else:
        vm_config.update(optional_keys_with_defaults)
    
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
        return hcl2.load(f)

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
        logger.error(f"Error while adding VM configuration: {str(e)}")
        raise

def delete_vm_config(vm_sid):
    try:
        config_path = get_config_path()
        data = load_hcl_config(config_path)

        vm_key = f"vm-{vm_sid}"
        if vm_key not in data['vms_config']:
            raise ValueError(f"No VM configuration found for {vm_sid}")
        
        del data['vms_config'][vm_key]
        save_hcl_config(data, config_path)
    except Exception as e:
        logger.error(f"Error while deleting VM configuration: {str(e)}")
        raise

def update_tfvars(vm_templates):
    vm_template_id = {name: int(id) for name, id in vm_templates.items()}

    with open('win11_cloudbase-init.auto.tfvars', 'r') as f:
        tfvars_content = f.readlines()

    start_line = next(i for i, line in enumerate(tfvars_content) if line.strip().startswith('vm_template_id = {')) + 1
    end_line = next((i for i, line in enumerate(tfvars_content[start_line:]) if line.strip() == '}'), len(tfvars_content)) + start_line

    del tfvars_content[start_line:end_line+1]

    for name, vm_id in vm_template_id.items():
        tfvars_content.insert(start_line, f'  "{name}" = {vm_id},\n')
    tfvars_content.insert(start_line + len(vm_template_id), '}\n')

    with open('win11_cloudbase-init.auto.tfvars', 'w') as f:
        f.writelines(tfvars_content)
