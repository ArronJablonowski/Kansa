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
        PSComputerName) as ct,
        Image,
        CommandLine, 
        SHA256,
        ParentImage,
        ParentCommandLine, 
        User,
        PSComputerName
    FROM
        *SysmonProcess*.csv
    WHERE        
        Image like '%psexec.exe' or
        Image like '%paexec%' or
        Image like '%mshta%' or
        Image like '%cscript.exe' or
        Image like '%wscript.exe' or
        Image like '%powershell.exe' or
        Image like '%System32\cmd.exe' or
        Image like '%SysWOW64\cmd.exe' or
        Image like '%wmic%' or
        Image like '%certutil.exe' or
        Image like '%bitsadmin.exe' or
        Image like '%Utilman%' or
        Image like '%node.exe' or
        Image like '%python%' or
        Image like '%mofcomp.exe' or
        Image like '%cmstp.exe' or
        Image like '%windbg.exe' or
        Image like '%cdb.exe' or
        Image like '%msbuild.exe' or
        Image like '%mstsc.exe' or
        Image like '%csc.exe' or
        Image like '%regsvr32.exe' or
        CommandLine like '%psexec%' or
        CommandLine like '%paexec%' or
        CommandLine like '%wmic%' or
        CommandLine like '%debug%'
    GROUP BY
        Image,
        CommandLine, 
        SHA256,
        ParentImage,
        ParentCommandLine, 
        User,
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
