<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR Autorunsc
#>
Get-ChildItem -Path ".\..\..\" -Filter "*Autorunsc.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([Signer],
        [Image Path], 
        [Launch String],
        [Entry Location]) as ct,
        [Signer],
        [Image Path], 
        [Launch String],
        [Entry Location]
    FROM
        *Autorunsc.csv
    GROUP BY
        [Signer],
        [Image Path], 
        [Launch String],
        [Entry Location]    
    ORDER BY
        [Image Path], 
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
