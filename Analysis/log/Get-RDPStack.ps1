<#
.SYNOPSIS
Need to comment 

 
.NOTES
DATADIR RdpConnectionLogs
#>
Get-ChildItem -Path ".\..\..\" -Filter "*RdpConnectionLogs.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([MachineNae],
        [SourceIP], 
        [UserName]) as ct,
        [MachineNae],
        [SourceIP], 
        [UserName]
    FROM
        *RdpConnectionLogs.csv
    GROUP BY
        [MachineNae],
        [SourceIP], 
        [UserName]
    ORDER BY
        [ct] ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
