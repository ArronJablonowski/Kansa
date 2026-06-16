<#
.SYNOPSIS
Get-ProcsWMIPathStack.ps1

Pulls frequency of processes based on path ProcessName Path & Hash 

Requires:
logparser.exe in path
.NOTES
DATADIR ProcImgPath
#>
Get-ChildItem -Path ".\..\..\" -Filter "*ProcImgPath.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}
if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(ProcessName,
        Path, 
        FileVersion,
        FileHash) as ct,
        ProcessName,
        Path,
        FileVersion,
        FileHash
    FROM
        *ProcImgPath.csv
    GROUP BY
        ProcessName,
        Path,
        FileVersion,
        FileHash
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
