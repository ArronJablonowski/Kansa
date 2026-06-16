<#
.SYNOPSIS
This script will audit some of the OS hardening configs  

.NOTES
by: Aj

#>
## Run OS Hardening Checks 
## =======================

# OS Version 
$str_OSVersion = Get-WmiObject win32_operatingsystem | Select-Object Version
# Check SNMP
$str_SNMP = Get-WindowsOptionalFeature -Online -FeatureName SNMP | Select-Object -ExpandProperty State
# Check SimpleTCP
$str_SimpleTCP = Get-WindowsOptionalFeature -Online -FeatureName SimpleTCP | Select-Object -ExpandProperty State
# Check Telnet
$str_Telnet = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient | Select-Object -ExpandProperty State
# Check TFTP
$str_TFTP = Get-WindowsOptionalFeature -Online -FeatureName TFTP | Select-Object -ExpandProperty State
# CHeck PowerShellv2
$str_PowerShellv2 = Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 | Select-Object -ExpandProperty State
# Check SMBv1
$str_SMBv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Select-Object -ExpandProperty State

# Check DEP (Data Execution Prevention -> Helps to fend off Buffer Overflows by randomizing memory locations)
$a = BCDEdit /enum "{current}" | Select-String 'nx'
$a = $a -replace 'nx',''
$depStatus = $a.Trim()

# Check LLMNR 
$str_LLMNR = (Get-ItemProperty -path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\' -name 'EnableMulticast').EnableMulticast
if($str_LLMNR -eq 0) { 
    $str_LLMNR = 'Disabled'
} else {
    $str_LLMNR = 'Enabled'
} 

#NetBIOS
# check with: nbtstatus -n 
# error when off:
#    Failed to access NetBT driver -- NetBT may not be loaded

#Make PS Object 
$OSConfigObject = New-Object -TypeName psobject 
$OSConfigObject | Add-Member -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
$OSConfigObject | Add-Member -MemberType NoteProperty -Name OSVersion -Value $str_OSVersion.Version
$OSConfigObject | Add-Member -MemberType NoteProperty -Name DEP -Value $depStatus
$OSConfigObject | Add-Member -MemberType NoteProperty -Name SNMP -Value $str_SNMP
$OSConfigObject | Add-Member -MemberType NoteProperty -Name SimpleTCP -Value $str_SimpleTCP
$OSConfigObject | Add-Member -MemberType NoteProperty -Name Telnet -Value $str_Telnet
$OSConfigObject | Add-Member -MemberType NoteProperty -Name TFTP -Value $str_TFTP
$OSConfigObject | Add-Member -MemberType NoteProperty -Name Powershellv2 -Value $str_PowerShellv2
$OSConfigObject | Add-Member -MemberType NoteProperty -Name SMBv1 -Value $str_SMBv1
$OSConfigObject | Add-Member -MemberType NoteProperty -Name LLMNR -Value $str_LLMNR

$OSConfigObject
