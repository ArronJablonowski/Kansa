<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR SysmonNetwork*
#>
Get-ChildItem -Path ".\..\..\" -Filter "*SysmonNetwork*.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(Image,
        DestinationIp, 
        DestinationHostname,
        PSComputerName) as ct,
        Image,
        DestinationIp, 
        DestinationHostname,
        PSComputerName
    FROM
        *SysmonNetwork*.csv
    WHERE
        Image like '%Mstsc.exe'
    GROUP BY
        Image,
        DestinationIp, 
        DestinationHostname,
        PSComputerName    
    ORDER BY
        Image,
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
