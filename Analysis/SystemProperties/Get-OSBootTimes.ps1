<#
.SYNOPSIS
Get-OSStack.ps1
Requires logparser.exe in path
Pulls frequency of OS 

This script expects files matching the *WMIOperatingSystem.csv pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR SystemBootTime
#>

#Delete files smaller than 500 bytes in an effort to not break this script 
Get-ChildItem -Path ".\..\..\" -Filter "*SystemBootTime.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(csname, lastbootuptime) as ct,
        csname, 
        lastbootuptime
    FROM
        *SystemBootTime.csv
    GROUP BY
        csname, 
        lastbootuptime
    ORDER BY
		csname,
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
