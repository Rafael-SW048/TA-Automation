from flask import jsonify
import paramiko
import logging
import subprocess
import requests

logger = logging.getLogger(__name__)

def runRemote(command, hostname="10.11.1.181", username="root", password="", runOnAllNodes=False):
  """
  This function runs a command on a remote machine via SSH.

  Parameters:
      command (str): The command to run.
      hostname (str): The hostname or IP address of the remote machine.
      username (str): The username to use for the SSH connection.
      password (str): The password to use for the SSH connection.
      run_on_all_nodes (bool): Whether to run the command on all nodes or just one node.

  Returns:
      str: The output of the command.
  """
  try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    # ssh.connect(hostname, username=username, password=password)
    output = ''

    if runOnAllNodes:
      hostips = ['10.11.1.181', '10.11.1.182']  # Replace with your actual hostnames

      for hostip in hostips:
        ssh.connect(hostip, username=username, password=password)
        stdin, stdout, stderr = ssh.exec_command(command)
        output += "Run on: " + hostip + ":\n"
        output += stdout.read().decode('utf-8')

      ssh.close()

      return output
    else:
      ssh.connect(hostname, username=username, password=password)
      stdin, stdout, stderr = ssh.exec_command(command)
      output += "Run on: " + hostname  + ":\n"
      output += stdout.read().decode('utf-8')

      ssh.close()

      return output
  except Exception as e:
    logging.error("Error during remote command execution to " + hostname + ": " + str(e), exc_info=True)
    return "Error during remote command execution to " + hostname + ": " + str(e)

def create_response(message, code, status='success', details=""):
    response = {status: {"code": code, "message": message}}
    if details:
        response["details"] = details
    return jsonify(response)

def handle_subprocess(command):
    try:
        output = subprocess.check_output(command, shell=True)
        return output.decode('utf-8')
    except subprocess.CalledProcessError as e:
        logger.error("Subprocess error: %s", e, exc_info=True)
        raise

def check_node_availability(node):
    try:
        response = requests.get(f"{node['url']}/health")
        if response.status_code == 200:
            return True
    except requests.exceptions.RequestException as e:
        logger.error("Node check request error: %s", e, exc_info=True)
    return False