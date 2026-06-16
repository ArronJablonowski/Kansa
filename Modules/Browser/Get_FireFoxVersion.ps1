<#
Get_FireFoxVersion.ps1

Gets FF current version 

#>

# get Chromer version 
$firefox = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe').'(Default)').VersionInfo.FileVersion

# get host name 
$hostname = $env:COMPUTERNAME

#Create an object for CS PSObj output 
$Obj = new-object PSObject -property @{HostName=$hostname;FireFoxVersion=$firefox;}

$Obj | select-object -property HostName, FireFoxVersion
