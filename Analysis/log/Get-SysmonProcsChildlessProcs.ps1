<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR *SysmonProcess*
#>
Get-ChildItem -Path ".\..\..\" -Filter "*SysmonProcess*.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(Image,
        CommandLine, 
        SHA256,
        ParentImage,
        ParentCommandLine, 
        User,
        PSComputerName,
        DateUTC) as ct,
        Image,
        CommandLine, 
        SHA256,
        ParentImage,
        ParentCommandLine, 
        User,
        PSComputerName,
        DateUTC
    FROM
        *SysmonProcess*.csv
    WHERE
        ParentImage like '%lsass.exe' or
        ParentImage like '%lsm.exe' or 
        Image like '%efsui.exe'
    GROUP BY
        Image,
        CommandLine, 
        SHA256,
        ParentImage,
        ParentCommandLine, 
        User,
        PSComputerName,
        DateUTC
    ORDER BY
        Image,
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
