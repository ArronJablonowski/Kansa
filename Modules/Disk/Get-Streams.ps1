<#
.SYNOPSIS
Get-Streams.ps1    

.NOTES
OUTPUT bin
Next line is required by Kansa for proper handling of third-party binary.
The BINDEP directive below tells Kansa where to find the third-party code.
BINDEP .\Modules\bin\streams.exe


#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [string]$searchPath="C:\Windows\"  # if path not specified, audit C:\ drive 
)

if (Test-Path "$env:SystemRoot\streams.exe") {
    & $env:SystemRoot\streams.exe /accepteula -s "$searchPath" -nobanner  2> $null | ConvertFrom-Csv | ForEach-Object {
        $_ 
    }
} else {
    Write-Error "streams.exe not found in $env:SystemRoot."
}