# Get the disk number of the disk to extend
$diskNumber = Get-Disk | Where-Object {$_.IsBoot -eq $false -and $_.IsSystem -eq $false} | Select-Object -ExpandProperty Number

# Extend the disk using Diskpart
$diskpartScript = "select disk $diskNumber`nextend`nexit`n"
Start-Process -FilePath "diskpart.exe" -ArgumentList "/s `"$diskpartScript`"" -NoNewWindow -Wait