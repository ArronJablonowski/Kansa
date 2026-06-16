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
        Image not like '%chrome.exe' and
        Image not like '%firefox.exe' and
        Image not like '%zoom.exe' and
        Image not like '%slack.exe' and
        Image not like '%FuzeInstallerPerUser.exe' and
        Image not like '%GoogleUpdate.exe' and
        DestinationIp not like '10.%' and
        DestinationIp not like '192.168.%' and
        DestinationIp not like '172.16%' and
        DestinationIp not like '172.17%' and
        DestinationIp not like '172.18%' and
        DestinationIp not like '172.19%' and
        DestinationIp not like '172.20%' and
        DestinationIp not like '172.21%' and
        DestinationIp not like '172.22%' and
        DestinationIp not like '172.23%' and
        DestinationIp not like '172.24%' and
        DestinationIp not like '172.25%' and
        DestinationIp not like '172.26%' and
        DestinationIp not like '172.27%' and
        DestinationIp not like '172.28%' and
        DestinationIp not like '172.29%' and
        DestinationIp not like '172.30%' and
        DestinationIp not like '172.31%' and
        DestinationIp not like '169.254%' and
        DestinationIp not in ('*'; '0.0.0.0'; 
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
