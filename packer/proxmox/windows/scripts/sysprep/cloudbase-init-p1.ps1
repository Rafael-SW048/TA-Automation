# install Cloudbase-Init
mkdir "c:\setup"
echo "Copy CloudbaseInitSetup_Stable_x64.msi"
copy-item "G:\sysprep\CloudbaseInitSetup_1_1_4_x64.msi" "c:\setup\CloudbaseInitSetup_1_1_4_x64.msi" -force

echo "Start process CloudbaseInitSetup_1_1_4_x64.msi"
start-process -FilePath 'c:\setup\CloudbaseInitSetup_1_1_4_x64.msi' -ArgumentList '/qn /l*v C:\setup\cloud-init.log' -Wait