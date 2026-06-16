<#
.SYNOPSIS
Need to comment 

 
.NOTES
DATADIR ChromeExtensionListing
#>
Get-ChildItem -Path ".\..\..\" -Filter "*ChromeExtensionListing.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([Name],
        [Extension], 
        [Sync]) as ct,
        [Name], 
        [Extension],
        [Sync]
    FROM
        *ChromeExtensionListing.csv
    GROUP BY
        [Name], 
        [Extension],
        [Sync]
    ORDER BY
        [ct] ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
