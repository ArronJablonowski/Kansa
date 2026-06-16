<#
.SYNOPSIS
Get-ProcsWMIPathStack.ps1

Pulls frequency of processes based on path ProcessName Path & Hash 

Requires:
logparser.exe in path
.NOTES
DATADIR ProcsWMI
#>
Get-ChildItem -Path ".\..\..\" -Filter "*ProcsWMI.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}
if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Path,
        Caption, 
        CommandLine) as ct,
        Path,
        Caption, 
        CommandLine
    FROM
        *ProcsWMI.csv
    GROUP BY
        Path,
        Caption, 
        CommandLine
    ORDER BY
        Path,
        Caption, 
        CommandLine,
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
