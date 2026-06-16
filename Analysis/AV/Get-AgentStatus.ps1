<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR AuditAgentsInstalled
#>
Get-ChildItem -Path ".\..\..\" -Filter "*AuditAgentsInstalled.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([PSComputerName],
        [TrendAV],
        [NessusAgent], 
        [BMCAgent]) as ct,
        [PSComputerName],
        [TrendAV],
        [NessusAgent], 
        [BMCAgent]
    FROM
        *AuditAgentsInstalled.csv
    WHERE
        [TrendAV] like 'MISSING' or
        [NessusAgent] like 'MISSING' or
        [BMCAgent] like 'MISSING'        
    GROUP BY
        [PSComputerName],    
        [TrendAV],
        [NessusAgent], 
        [BMCAgent]
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
