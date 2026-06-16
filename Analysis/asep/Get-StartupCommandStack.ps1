<#
.SYNOPSIS
Get-StartupCommand.ps1
Requires logparser.exe in path
Pulls frequency of StartupCommand entries

This script expects files matching the *StartupCommand.csv pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR StartupCommand
#>

#Delete files smaller than 500 bytes in an effort to not break this script 
Get-ChildItem -Path ".\..\..\" -Filter "*StartupCommand.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 500} | ?{Remove-Item $_.fullname}
#Get-ChildItem -Path ".\..\..\" -Filter "*SmbShare.csv" -Recurse | Set-ItemProperty $_ -name IsReadOnly -value $false
New-Item -path ".\..\..\Output*\StartupCommand\" -Name "AllStartupCommands.csv"
Start-Sleep -s 2
Import-csv -path (Get-ChildItem -Path ".\..\..\Output*" -Filter "*StartupCommand.csv" -Recurse) | Select-Object Caption,Command | Export-Csv -Path ".\..\..\Output*\StartupCommand\AllStartupCommands.csv" -NoTypeInformation
Start-Sleep -s 2 

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Caption, Command) as ct,
        Caption,
        Command
    FROM
        *AllStartupCommands.csv
    GROUP BY
        Caption,
        Command
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
