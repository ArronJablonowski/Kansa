#Start-Process -FilePath "C:\Program Files (x86)\Trend Micro\OfficeScan Client\Pccnt.exe" -ArgumentList "C:\"
Start-Process -WindowStyle Hidden -FilePath "C:\Program Files (x86)\Trend Micro\OfficeScan Client\Wofielauncher.exe" -ArgumentList "-manual_scan_target C:\" 
Write-Output "Trend Scan started on $env:COMPUTERNAME "