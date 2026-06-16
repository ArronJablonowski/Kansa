<#
.SYNOPSIS
Get-ARPStack.ps1
Requires logparser.exe in path
Pulls frequency of ARP based on IpAddr

This script expects files matching the *ArpEXE.csv pattern to be in the
current working directory.

Simsay, Jason: Modified for LogParser output to CSV.
.NOTES
DATADIR ArpEXE
#>


if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(IpAddr, Mac, Type) as ct,
        IpAddr,
        Mac,
        Type
    FROM
        *ArpEXE.csv
    GROUP BY
        IpAddr,
        Mac,
        Type
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

