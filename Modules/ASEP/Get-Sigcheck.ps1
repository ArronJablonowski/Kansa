<#
.SYNOPSIS
Get-Sigcheck.ps1 returns output from the SysInternals' sicheck.exe utility

.NOTES
OUTPUT csv
BINDEP .\Modules\bin\sigcheck.exe

!! THIS SCRIPT ASUMES SIGCHECK.EXE WILL BE IN $ENV:SYSTEMROOT !!
#>

#Path to search recursively #$searchPath = "C:\Windows\System32"
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [string]$searchPath="$env:SystemRoot\System32\"  # if path not specified, audit C:\Windows\System32 
)

if (Test-Path "$env:SystemRoot\sigcheck.exe") {
    & $env:SystemRoot\sigcheck.exe /accepteula -a -e -c -h -q -s -r "$searchPath" |
    ConvertFrom-Csv -Header Path, Verified, 
    SigningDate, Publisher, Company, Description, Product, ProductVersion, FileVersion, MachineType, BinaryVersion, 
    OriginalName, InternalName, Copyright, Comments, Entropy, MD5, SHA1, PESHA1, PE256, SHA256, IMP | 
    Where-Object { $_.Path -ne $exclude } 
}
else {
    Write-Error "Sigcheck.exe not found in $env:SystemRoot."
}