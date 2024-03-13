# Check if Chocolatey is installed
$choco_installed = $null -ne (Get-Command choco -ErrorAction SilentlyContinue)

# Install Chocolatey if it's not installed
if (-not $choco_installed)
{
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  iex ((Invoke-WebRequest -UseBasicParsing -Uri https://chocolatey.org/install.ps1).Content)
}

# Install Packer
choco install packer -y

# Install VirtualBox Packer Plugins
packer plugin install packer-plugin-virtualbox


# Run Packer to create a new Ubuntu ISO
packer build boilerplates\packer\virtualbox\ubuntu-desktop-docker\ubuntu-desktop-docker.pkr.hcl