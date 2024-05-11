param (
  [Parameter(Mandatory=$true)]
  [string]$newName
)

$currentName = $env:computername
# Use SID as the new name
if ($newName -eq '') { Write-Host 'Error: Please enter a new computer name.'; exit 1 }
Try { Rename-Computer -NewName $newName -Force; Write-Host 'Successfully renamed the computer to ''$newName''.' }
Catch { Write-Error 'Failed to rename the computer: $($_.Exception.Message)'; exit 1 }
Write-Host 'The computer name change will take effect after a restart.'
Read-Host 'Press Enter to restart now, or any other key to cancel.'
if ($PSCurrentPipelineStatus.IsCompleted) { Restart-Computer -Force }