<#
.SYNOPSIS
Get-MappedDrives.ps1 acquires the drives mapped in the active user's current session from the target host.

.NOTES
The next line is required by Kansa.ps1, it tells Kansa how to handle the output returned.
OUTPUT csv
#>
#$ErrorActionPreference = "continue"
if(test-path -path hku:\ ) {}
Else {New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null}
$mapped = @()
$currUserHives = Get-ChildItem -Path HKU: | Where-Object {$_.name -match 'S-1-5-21-913984894-1886071815-1233803906' -and ($_.name -notmatch '_Classes')} | Select Name
if ($currUserHives.Name.count -gt 1) {
    $currUserHives.Name | ForEach-Object {
        $currUserHive = $_ -split("\\")
        $currUserHive = $currUserHive[1]
        $patha = "HKU:\"+$currUserHive.TrimStart(" ")+"\Volatile Environment"
        $pathb = "HKU:\"+$currUserHive.TrimStart(" ")+"\Network"
        $pathc = "HKU:\"+$currUserHive.TrimStart(" ")+"\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
        try {$user = Get-ItemProperty -Path $patha -ErrorAction Stop}
        catch {$user = "Volitile Environment Not Found; Unable to ID User"}
        finally {
            $user = $env:USERDNSDOMAIN+"\"+$user.USERNAME
            $drives = Get-ChildItem -Path $pathb | Get-ItemProperty | Select PSChildName,RemotePath
            $recent = Get-ChildItem -Path $pathc | Get-ItemProperty | Select PSChildName
            $recent = $recent.PSChildName | Where {$_ -match "##[a-zA-Z-_\\0-9$#\s]*"}
            $recent = $recent -replace("#","\")
            $other = $recent | ForEach-Object {
                if($drives.RemotePath -contains("$_") -eq $false) {$_}
                else {}
            }
            $drives | ForEach-Object {
                $drvltr = $_.PSChildName
                $drvpth = $_.RemotePath
                $drv = new-object PSObject -property @{DriveLetter=$drvltr;SharePath=$drvpth;User=$user}
                $mapped += $drv
            }
            $other | ForEach-Object {
                $drvltr = ""
                $drvpth = $_
                $drv = new-object PSObject -property @{DriveLetter=$drvltr;SharePath=$drvpth;User=$user}
                $mapped += $drv
            }
        }
    }
} Elseif ($currUserHives.Name.count -eq 1) {
    $currUserHive = $currUserHives.Name -split("\\")
    $currUserHive = $currUserHive[1]
    $patha = "HKU:\"+$currUserHive+"\Volatile Environment"
    $pathb = "HKU:\"+$currUserHive+"\Network"
    $pathc = "HKU:\"+$currUserHive+"\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
    try {$user = Get-ItemProperty -Path  $patha -ErrorAction Stop}
    catch {}
    finally {
        $user = $env:USERDNSDOMAIN+"\"+$user.USERNAME
        $drives = Get-ChildItem -Path  $pathb | Get-ItemProperty | Select PSChildName,RemotePath
        $recent = Get-ChildItem -Path $pathc | Get-ItemProperty | Select PSChildName
        $recent = $recent.PSChildName | Where {$_ -match "##[a-zA-Z-_\\0-9$#\s]*"}
        $recent = $recent -replace("#","\")
        $other = $recent | ForEach-Object {
            if($drives.RemotePath -contains("$_") -eq $false) {$_}
            else {}
        }
        $drives | ForEach-Object {
            $drvltr = $_.PSChildName
            $drvpth = $_.RemotePath
            $drv = new-object PSObject -property @{DriveLetter=$drvltr;SharePath=$drvpth;User=$user}
            $mapped += $drv
        }
        $other | ForEach-Object {
            $drvltr = ""
            $drvpth = $_
            $drv = new-object PSObject -property @{DriveLetter=$drvltr;SharePath=$drvpth;User=$user}
            $mapped += $drv
        }
    }
}
$mapped