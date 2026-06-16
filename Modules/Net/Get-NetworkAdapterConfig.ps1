<#
.SYNOPSIS
Get-NetIPInterfaces.ps1
Returns data from Get-NetIPInterface
.NOTES
Next line tells Kansa.ps1 how to format this script's output
OUTPUT tsv
#>
Get-WmiObject -Namespace root\cimv2 -Class Win32_NetworkAdapterConfiguration 

# | select ArpAlwaysSourceRoute,ArpUseEtherSNAP,Caption,DatabasePath,DeadGWDetectEnabled,DefaultIPGateway,DefaultTOS,DefaultTTL,Description,DHCPEnabled,DHCPLeaseExpires,DHCPLeaseObtained,DHCPServer,DNSDomain,DNSDomainSuffixSearchOrder