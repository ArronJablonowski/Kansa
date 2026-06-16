<#
.SYNOPSIS
This script will move sysinternals to the machine then run it. 

.NOTES
BINDEP .\Modules\bin\pslist.exe

!!THIS SCRIPT ASSUMES pslist.exe WILL BE IN $ENV:SYSTEMROOT!!
#>

& "$ENV:SYSTEMROOT\pslist.exe" -t -accepteula  2> $null | % {$_.replace(" ","_")} | ConvertFrom-Csv | ForEach-Object {
    $_ 
}
