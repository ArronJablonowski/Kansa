<#
.SYNOPSIS
Get-Last100AppEvents.ps1 returns the last 100 Application Event logs.
.NOTES
The next line is needed by Kansa.ps1 to determine how to handle output
from this script.
OUTPUT TSV

Contributed by Aj 
#>

Get-Eventlog -Logname application -Newest 100 | Sort-Object -Property TimeGenerated -descending