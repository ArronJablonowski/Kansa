<#
.SYNOPSIS
Get-IISStack.ps1
Requires logparser.exe in path
Pulls frequency of IIS Installed entries

This script expects files matching the *IIS.csv pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR IIS
#>

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(IISInstalled) as ct,
        IISInstalled
    FROM
        *IIS.csv
    GROUP BY
        IISInstalled
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

