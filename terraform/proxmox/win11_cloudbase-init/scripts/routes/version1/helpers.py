import paramiko
import logging

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