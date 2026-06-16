<#
.SYNOPSIS
Get-SvcTrigStack.ps1
Requires logparser.exe in path
Pulls stack rank of Service Triggers from acquired Service Trigger data

This script expects files matching the pattern *svctrigs.tsv to be in 
the current working directory.
.NOTES
DATADIR WMISystemDrivers
#>
Get-ChildItem -Path ".\..\..\" -Filter "*WMISystemDrivers.csv"  -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}
if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Name, DisplayName, PathName, StartMode) as ct, 
        Name, 
        DisplayName, 
        PathName, 
        StartMode
    FROM
        *WMISystemDrivers.csv 
    GROUP BY
        Name, 
        DisplayName, 
        PathName, 
        StartMode 
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
