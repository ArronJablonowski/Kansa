<#
.SYNOPSIS
Need to comment 

 
.NOTES
DATADIR Remove-KnownBadChromeExtensions
#>
Get-ChildItem -Path ".\..\..\" -Filter "*KnownBadChromeExtensions.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([Name],
        [DeletedExtension],
        [WindowsUser],
        [PSComputerName]) as ct,
        [Name], 
        [DeletedExtension],
        [WindowsUser],
        [PSComputerName],
        [Sync]
    FROM
        *KnownBadChromeExtensions.csv
    GROUP BY
        [Name], 
        [DeletedExtension],
        [WindowsUser],
        [PSComputerName],
        [Sync]
    ORDER BY
        [ct] ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
