<#
.SYNOPSIS
Need to comment 

 
.NOTES
DATADIR ChromeProfileInfo
#>
Get-ChildItem -Path ".\..\..\" -Filter "*ChromeProfileInfo.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([WindowsUser],
        [ComputerName],
        [SyncedUsername]) as ct,
        [WindowsUser],
        [ComputerName],
        [SyncedUsername]
    FROM
        *ChromeProfileInfo.csv
    GROUP BY
        [WindowsUser],
        [ComputerName],
        [SyncedUsername]
    ORDER BY
        [ct] ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
