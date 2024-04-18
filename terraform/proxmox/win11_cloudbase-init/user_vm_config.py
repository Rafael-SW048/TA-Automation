import json
import os

def load_vm_config_from_file():
  try:
    dir_path = os.path.dirname(os.path.realpath(__file__))
    file_path = os.path.join(dir_path, "temp.json")

    with open(file_path, "r") as file:
      data = json.load(file)
      vm_config = data.get("vm_config", {})
      return vm_config
  except FileNotFoundError:
    return {}

def main():
  try:
    vm_config = load_vm_config_from_file()

    if not vm_config:
      name = input("Enter VM name: ")
      desc = input("Enter VM description: ")
      cores = int(input("Enter VM cores (min: 6, max: 10): "))
      memory = int(input("Enter VM memory in GB (min: 8, max: 16): "))
    else:
      name = vm_config.get("name", "")
      desc = vm_config.get("desc", "")
      cores = vm_config.get("cores", 0)
      memory = vm_config.get("memory", 0)

    if not name:
      name = input("Enter VM name: ")
    if not desc:
      desc = input("Enter VM description: ")
    if not cores:
      while True:
        cores = int(input("Enter VM cores (min: 6, max: 10): "))
        if cores < 6 or cores > 10:
          print("Invalid number of cores. Please enter a value between 6 and 10.")
        else:
          break
    if not memory:
      while True:
        memory = int(input("Enter VM memory in GB (min: 8, max: 16): "))
        if memory < 8 or memory > 16:
          print("Invalid memory size. Please enter a value between 8 and 16.")
        else:
          break

    # Construct vm_config object
    vm_config = {
      "name": f"VM-CloudGaming-{name}",
      "desc": desc,
      "cores": cores,
      "memory": memory * 1024,
      "dns": "",
      "ip": "",
      "gateway": "",
    }

    # Write vm_config object to user_vm_config.tfvars
    file_path = os.path.join(os.path.dirname(__file__), "user_vm_config.auto.tfvars")
    with open(file_path, "w") as f:
      f.write("vm_config = {\n")
      for key, value in vm_config.items():
        if isinstance(value, str):
          f.write(f'  {key} = "{value}"\n')  # Wrap string values in quotes
        else:
          f.write(f"  {key} = {value}\n")
      f.write("}\n")
      print("user_vm_config.tfvars file generated successfully!")

  except Exception as e:
    print(f"Error: {e}")
  finally:
    print("Program execution completed.")

if __name__ == "__main__":
  main()
