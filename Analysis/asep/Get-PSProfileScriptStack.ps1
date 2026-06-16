<#
.SYNOPSIS
Get-PSProfileScriptStack.ps1
Requires logparser.exe in path
Pulls frequency of Scripts in the PS Profile's ASEP 

This script expects files matching the *PSProfiles.csv  pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR PSProfiles
#>

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Script) as ct,
        Script
    FROM
        *PSProfiles.csv 
    GROUP BY
        Script
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

