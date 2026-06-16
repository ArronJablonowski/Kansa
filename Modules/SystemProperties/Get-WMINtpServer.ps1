<#
.SYNOPSIS
Get-WMIOperatingSystem.ps1 returns information from the win32_operatingsystem class to aid in profiling systems based on operating system platform.
.NOTES
The following line is required by Kansa.ps1, which uses it to determine
how to handle the output from this script.
OUTPUT tsv
#>
Invoke-Command { w32tm /query /source } 