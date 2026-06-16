<#
.SYNOPSIS
Get-Get-PSProfileNameStack.ps1
Requires logparser.exe in path
Pulls frequency of PSProfile Users in the PS Profile's ASEP 

This script expects files matching the *PSProfiles.csv  pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR PSProfiles
#>

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Name) as ct,
        Name
    FROM
        *PSProfiles.csv 
    GROUP BY
        Name
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

