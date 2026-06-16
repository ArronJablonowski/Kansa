<#
.SYNOPSIS
Get-hostOSList.ps1
Requires logparser.exe in path
Pulls OS type and Host name  

This script expects files matching the *WMIOperatingSystem.csv pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR WMIOperatingSystem
#>

#Delete files smaller than 500 bytes in an effort to not break this script 
Get-ChildItem -Path ".\..\..\" -Filter "*WMIOperatingSystem.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Caption, OSArchitecture, PSComputerName) as ct,
        Caption,
        OSArchitecture,
        PSComputerName
    FROM
        *WMIOperatingSystem.csv
    GROUP BY
        Caption, 
        OSArchitecture,
        PSComputerName
    ORDER BY
        Caption,
        ct ASC
"@

& logparser -stats:off -i:csv -dtlines:0 -o:csv "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
