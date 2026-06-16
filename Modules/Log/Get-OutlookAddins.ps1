<#
.SYNOPSIS
Get-OutlookAddins.ps1 acquires Outlook add-ins from local machine and loaded user registry hives.

.NOTES
The next line is required by Kansa.ps1, it tells Kansa how to handle the output returned.
OUTPUT csv
#>

$outlookaddins = @()

function Ensure-HkuDrive {
    if (-not (Test-Path -Path HKU:\)) {
        try {
            New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "Unable to mount HKU registry drive: $($_.Exception.Message)"
            return $false
        }
    }

    return $true
}

function Add-OutlookAddinsFromKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [Parameter(Mandatory=$true)]
        [string]$Hive,
        [Parameter(Mandatory=$true)]
        [string]$User
    )

    if (-not (Test-Path -Path $Key)) {
        Write-Warning "Outlook add-in registry key was not found: $Key"
        return
    }

    try {
        Get-ChildItem -Path $Key -ErrorAction Stop | ForEach-Object {
            $prop = Get-ItemProperty -Path $_.PSPath -ErrorAction Stop |
                Select-Object PSChildName, LoadBehavior, FriendlyName, Description

            $script:outlookaddins += New-Object PSObject -Property @{
                PSChildName = $prop.PSChildName
                LoadBehavior = $prop.LoadBehavior
                FriendlyName = $prop.FriendlyName
                Description = $prop.Description
                Hive = $Hive
                User = $User
            }
        }
    }
    catch {
        Write-Warning "Unable to read Outlook add-ins from '$Key': $($_.Exception.Message)"
    }
}

function Get-LoadedUserName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Sid
    )

    $path = "HKU:\$Sid\Volatile Environment"
    if (-not (Test-Path -Path $path)) {
        Write-Warning "Username information was not found for loaded user hive $Sid."
        return "Username not found"
    }

    try {
        $user = Get-ItemProperty -Path $path -ErrorAction Stop
        if ($user.USERDOMAIN -and $user.USERNAME) {
            return "$($user.USERDOMAIN)\$($user.USERNAME)"
        }

        Write-Warning "USERDOMAIN or USERNAME was not found in $path."
        return "Username not found"
    }
    catch {
        Write-Warning "Unable to read username information from '$path': $($_.Exception.Message)"
        return "Username not found"
    }
}

function Get-UserOutlookAddinKeys {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Sid
    )

    $keys = @("HKU:\$Sid\SOFTWARE\Microsoft\Office\Outlook\Addins")
    $officeRoot = "HKU:\$Sid\SOFTWARE\Microsoft\Office"

    if (-not (Test-Path -Path $officeRoot)) {
        Write-Warning "Microsoft Office registry root was not found for loaded user hive $Sid."
        return $keys
    }

    try {
        Get-ChildItem -Path $officeRoot -ErrorAction Stop |
            Where-Object { $_.PSChildName -match '^[0-9]{2}\.[0-9]$' } |
            ForEach-Object {
                $keys += Join-Path $_.PSPath 'Outlook\Addins'
            }
    }
    catch {
        Write-Warning "Unable to enumerate Office versions for loaded user hive ${Sid}: $($_.Exception.Message)"
    }

    return $keys | Select-Object -Unique
}

$lmkeys = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office\Outlook\Addins", "HKLM:\SOFTWARE\Microsoft\Office\Outlook\Addins"
$lmkeys | ForEach-Object {
    $key = $_
    $hive = $key -replace "HKLM:", "HKEY_LOCAL_MACHINE"
    Add-OutlookAddinsFromKey -Key $key -Hive $hive -User "N/A"
}

if (Ensure-HkuDrive) {
    $loadedUserHives = Get-ChildItem -Path HKU:\ -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -match '^S-1-5-\d' -and $_.PSChildName -notmatch '_Classes$' }

    if (-not $loadedUserHives) {
        Write-Warning "No loaded user registry hives were found under HKEY_USERS."
    }

    $loadedUserHives | ForEach-Object {
        $sid = $_.PSChildName
        $user = Get-LoadedUserName -Sid $sid

        Get-UserOutlookAddinKeys -Sid $sid | ForEach-Object {
            $key = $_
            $hive = $key -replace "HKU:", "HKEY_USERS"
            Add-OutlookAddinsFromKey -Key $key -Hive $hive -User $user
        }
    }
}

if (-not $outlookaddins) {
    Write-Warning "No Outlook add-ins were found in the checked registry locations."
}

$outlookaddins | Select-Object Hive, PSChildName, LoadBehavior, FriendlyName, Description, User
