<#
.SYNOPSIS
Get-StartupCommand.ps1 returns information from the win32_StarupCommand class to aid in finding ASEPs.
.NOTES
The following line is required by Kansa.ps1, which uses it to determine
how to handle the output from this script.
OUTPUT tsv
#>
Get-WmiObject -Namespace root\cimv2 Win32_StartupCommand