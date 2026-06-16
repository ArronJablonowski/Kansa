<#
.SYNOPSIS
Get-WMICProcListFull.ps1 returns data about installed hotfixes.
.NOTES
The next line is needed by Kansa.ps1 to determine how to handle output
from this script.
OUTPUT TSV

Contributed by Aj 
#>

wmic process list full 