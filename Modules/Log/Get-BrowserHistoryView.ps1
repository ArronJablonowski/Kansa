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

        if (Test-Path -LiteralPath $outfile -PathType Leaf) {
            $csv = Import-Csv $outfile -ErrorAction SilentlyContinue
            if ($csv) {
                $csv
            }
            else {
                Write-Warning "BrowsingHistoryView completed but no browser history records were found in '$outfile'."
            }
        }
        else {
            Write-Warning "BrowsingHistoryView completed but did not create '$outfile'. Browser history may not exist for this user or browser profile."
        }

        Start-Sleep -Seconds 2
        Remove-Item $outfile -ErrorAction SilentlyContinue #remove log file 
} else {
    Write-Warning "BrowsingHistoryView.exe was not found in $env:SystemRoot. Browser history was not collected."
}
