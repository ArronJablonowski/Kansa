<#
.SYNOPSIS
Get-UserQuery returns a list of logged in users.
.NOTES
Next line is required by Kansa.ps1. It instructs Kansa how to handle
the output from this script.
OUTPUT tsv
#>

#query user
$data = @()
$NetLogs = Get-WmiObject Win32_NetworkLoginProfile
foreach ($NetLog in $NetLogs) {
if ($NetLog.LastLogon -match "(\d{14})") {
$row = "" | Select Name,LogonTime
$row.Name = $NetLog.Name
$row.LogonTime=[datetime]::ParseExact($matches[0], "yyyyMMddHHmmss", $null)
$data += $row}}
$data |Sort -Property "Logon Time"