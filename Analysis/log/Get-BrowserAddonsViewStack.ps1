<#
.SYNOPSIS
Need to comment 

    WHERE        
        DestinationIp not in ('0.0.0.0'; 
            '127.0.0.1')
    GROUP BY
        Process
 
.NOTES
DATADIR BrowserAddonsView
#>
Get-ChildItem -Path ".\..\..\" -Filter "*BrowserAddonsView.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT([Item ID],
        [Status],
        [Web Browser],
        [Addon Type],
        [Name],
        [Version],
        [Description],
        [Title],
        [Creator],
        [Addon Filename]) as ct,
        [Item ID],
        [Status],
        [Web Browser],
        [Addon Type],
        [Name],
        [Version],
        [Description],
        [Title],
        [Creator],
        [Addon Filename]
    FROM
        *BrowserAddonsView.csv
    GROUP BY
        [Item ID],
        [Status],
        [Web Browser],
        [Addon Type],
        [Name],
        [Version],
        [Description],
        [Title],
        [Creator],
        [Addon Filename]
    ORDER BY
        [ct] ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -o:csv $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
