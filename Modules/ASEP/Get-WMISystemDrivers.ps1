<#
.SYNOPSIS
Get-WMISystemDrivers.ps1 returns information from the win32_systemdriver class.
.NOTES
The following line is required by Kansa.ps1, which uses it to determine
how to handle the output from this script.
OUTPUT tsv
#>
Get-WmiObject -Class win32_systemdriver | Select Name, InstallDate, DisplayName, PathName, State, StartMode