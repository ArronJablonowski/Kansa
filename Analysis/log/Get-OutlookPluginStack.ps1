<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR OutlookAddins
#>
Get-ChildItem -Path ".\..\..\" -Filter "*OutlookAddins.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([PSChildName],
        [FriendlyName],
        [Description]) as ct,
        [PSChildName],
        [FriendlyName],
        [Description]
    FROM
        *OutlookAddins.csv
    GROUP BY
        [PSChildName],
        [FriendlyName],
        [Description]   
    ORDER BY 
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
