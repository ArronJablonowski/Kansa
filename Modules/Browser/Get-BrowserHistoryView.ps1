<#
.SYNOPSIS
Get-*.ps1 ... 

.NOTES
The following lines are required by Kansa.ps1. They are directives that
tell Kansa how to treat the output of this script and where to find the
binary that this script depends on.
OUTPUT tsv
BINDEP .\Modules\bin\BrowsingHistoryView.exe

!!THIS SCRIPT ASSUMES BrowsingHistoryView.exe WILL BE IN $ENV:SYSTEMROOT!!
#>

if (Test-Path "$env:SystemRoot\BrowsingHistoryView.exe") {  #Version 2.21 x64
        $outfile = ".\"+$env:COMPUTERNAME+"_BrowsingHistory.csv"
        $cmdLineOptions = "/HistorySource 1", "/VisitTimeFilterType 1", '/sort "~Visit Time"',  "/LoadIE 1", "/LoadFirefox 1", "/LoadChrome 1", "/LoadSafari 1", "/scomma $outfile"
        Start-Process -Filepath "$env:SystemRoot\BrowsingHistoryView.exe" -ArgumentList $cmdLineOptions -NoNewWindow -Wait
        Start-Sleep -Seconds 2 # let file rest for 2 seconds so it is not locked/in use 
        $csv = Import-Csv $outfile 
        $csv  
        Start-Sleep -Seconds 2
        Remove-Item $outfile #remove log file 
} else {
    Write-Error "BrowsingHistoryView.exe not found in $env:SystemRoot."
}