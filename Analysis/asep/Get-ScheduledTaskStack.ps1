<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR SchedTasks
#>
Get-ChildItem -Path ".\..\..\" -Filter "*SchedTasks.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([TaskName],
        [Task to Run], 
        [Author]) as ct,
        [TaskName],
        [Task to Run], 
        [Author]
    FROM
        *SchedTasks.csv
    WHERE
        [TaskName] not like 'TaskName' 
    GROUP BY
        [TaskName],
        [Task to Run], 
        [Author]    
    ORDER BY
        [Task to Run], 
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
