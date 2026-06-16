<#
.SYNOPSIS
Get-SMBShareStack.ps1
Requires logparser.exe in path
Pulls frequency of Smb Share entries

This script expects files matching the *SmbShare.csv pattern to be in the
current working directory.

Aj: Modified for LogParser output to CSV.
.NOTES
DATADIR SmbShare
#>

#Delete files smaller than 500 bytes in an effort to not break this script 
Get-ChildItem -Path ".\..\..\" -Filter "*SmbShare.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 500} | ?{Remove-Item $_.fullname}
#Get-ChildItem -Path ".\..\..\" -Filter "*SmbShare.csv" -Recurse | Set-ItemProperty $_ -name IsReadOnly -value $false
New-Item -path ".\..\..\Output*\SmbShare\" -Name "AllSmbShares.csv"

Import-csv -path (Get-ChildItem -Path ".\..\..\Output*" -Filter "*SmbShare.csv" -Recurse) | Select-Object Name,Path | Export-Csv -Path ".\..\..\Output*\SmbShare\AllSmbShares.csv" -NoTypeInformation
Start-Sleep -s 2 

if (Get-Command logparser.exe) {
    $lpquery = @"
    SELECT
        COUNT(Name,Path) as ct,
        Name,
		Path
    FROM
        *AllSmbShares.csv
    GROUP BY
        Name,
		Path
    ORDER BY
        ct ASC
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}

