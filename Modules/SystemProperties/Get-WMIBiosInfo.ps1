<#
.SYNOPSIS
Get-WMIBiosInfo.ps1 returns information from the win32_bios class to aid in profiling systems.
.NOTES
The following line is required by Kansa.ps1, which uses it to determine
how to handle the output from this script.
OUTPUT tsv
#>
get-wmiobject -class win32_bios | Select-Object PSComputerName,BIOSVersion,Caption,Description,Manufacturer,PrimaryBIOS,ReleaseDate,SerialNumber,SMBIOSBIOSVersion,Version,BuildNumber,Name

