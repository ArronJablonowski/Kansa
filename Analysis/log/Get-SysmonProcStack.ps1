<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR SysmonProcess*
#>
Get-ChildItem -Path ".\..\..\" -Filter "*SysmonProcess*.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(Image,
        CommandLIne, 
        SHA256,
        ParentImage) as ct,
        Image,
        CommandLIne, 
        SHA256,
        ParentImage
    FROM
        *SysmonProcess*.csv
    WHERE
        Image not like '%FireFox.exe' and
        Image not like '%Chrome.exe' and
        Image not like '%64bitProxy.exe'    
    GROUP BY
        Image,
        CommandLIne, 
        SHA256,
        ParentImage    
    ORDER BY
        Image,
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
