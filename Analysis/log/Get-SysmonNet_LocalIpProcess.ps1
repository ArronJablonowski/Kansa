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
        DestinationIp like '10.%' or
        DestinationIp like '192.168.%' or
        DestinationIp like '172.16%' or
        DestinationIp like '172.17%' or
        DestinationIp like '172.18%' or
        DestinationIp like '172.19%' or
        DestinationIp like '172.20%' or
        DestinationIp like '172.21%' or
        DestinationIp like '172.22%' or
        DestinationIp like '172.23%' or
        DestinationIp like '172.24%' or
        DestinationIp like '172.25%' or
        DestinationIp like '172.26%' or
        DestinationIp like '172.27%' or
        DestinationIp like '172.28%' or
        DestinationIp like '172.29%' or
        DestinationIp like '172.30%' or
        DestinationIp like '172.31%' or
        DestinationIp like '169.254%' or
        DestinationIp in ('*'; '0.0.0.0'; 
            '127.0.0.1'; '[::]'; '[::1]')    
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
