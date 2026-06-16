<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR BrowserHistoryView
#>
Get-ChildItem -Path ".\..\..\" -Filter "*BrowserHistoryView.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([URL],
        [Title],
        [Visit Time], 
        [Visited From],
        [Visit Type], 
        [Web Browser],
        [User Profile], 
        [Browser Profile]) as ct,
        [URL],
        [Title],
        [Visit Time], 
        [Visited From],
        [Visit Type], 
        [Web Browser],
        [User Profile], 
        [Browser Profile]
    FROM
        *BrowserHistoryView.csv
    WHERE
        [Web Browser] like 'Chrome' or
        [Web Browser] like 'Chrom%'
    GROUP BY
        [URL],
        [Title],
        [Visit Time], 
        [Visited From],
        [Visit Type], 
        [Web Browser],
        [User Profile], 
        [Browser Profile]   
    ORDER BY
        [Visit Time] ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
