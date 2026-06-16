<#
.SYNOPSIS
Get-FirewallStatusStack.ps1
Requires logparser.exe in path
Pulls frequency of OS 

This script expects files matching the *FirewallStatus.csv pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR FirewallStatus
#>

#Delete files smaller than 300 bytes in an effort to not break this script 
Get-ChildItem -Path ".\..\..\" -Filter "*FirewallStatus.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        PSComputerName,
        Profile,
        Enabled
    FROM
        *FirewallStatus.csv
    ORDER BY
		PSComputerName    
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
