<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR WMIEvtConsumer
#>
Get-ChildItem -Path ".\..\..\" -Filter "*WMIEvtConsumer.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([Name], 
        [__RELPATH],
        [__CLASS]) as ct,
        [Name], 
        [__RELPATH],
        [__CLASS]
    FROM
        *WMIEvtConsumer.csv
    GROUP BY
        [Name], 
        [__RELPATH],
        [__CLASS]
    ORDER BY
        [Name], 
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
