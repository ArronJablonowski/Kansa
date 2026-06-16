<#
.SYNOPSIS
Get-WMIPhysicalMedia.ps1 returns information from the win32_PhysicalMedi class to summarize local drive info.
.NOTES
The following line is required by Kansa.ps1, which uses it to determine
how to handle the output from this script.
OUTPUT tsv
#>
Get-WmiObject Win32_PhysicalMedia | select Capacity,Caption,Description,InstallDate,Manufacturer,MediaDescription,MediaType,Model,Name,PartNumber,PoweredOn,Removable,SerialNumber,Status,Tag,Version