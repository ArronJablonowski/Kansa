<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR chocolateyVersion
#>
#Get-ChildItem -Path ".\..\..\" -Filter "*chocolateyVersion.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(Version,
        PSComputerName) as ct,
        Version, 
        PSComputerName
    FROM
        *chocolateyVersion.csv
    WHERE
        Version not like 'None' and
        Version not like 'none' and 
        Version not like 'choco%'  
    GROUP BY
        Version, 
        PSComputerName    
    ORDER BY
        Version,
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
