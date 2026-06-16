#Requires -Version 3.0

<#
PowerShell implementation of Kansa_GUI.au3.

This keeps the AutoIt GUI's workflow:
- choose local or remote incident response
- choose a remote single host or host list
- choose a saved module configuration
- copy Modules.conf and optional Analysis.conf into place
- stage hostlist.txt for remote runs
- launch the matching Kansa runner script in a visible console
#>

function Get-PowerShellExecutable {
    $sysnativeWindowsPowerShell = Join-Path $env:WINDIR 'Sysnative\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path -LiteralPath $sysnativeWindowsPowerShell -PathType Leaf) {
        return $sysnativeWindowsPowerShell
    }

    $nativeWindowsPowerShell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path -LiteralPath $nativeWindowsPowerShell -PathType Leaf) {
        return $nativeWindowsPowerShell
    }

    $powershellPath = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
    if (-not $powershellPath) {
        $powershellPath = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
    }

    return $powershellPath
}

function Test-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

if (-not (Test-IsAdministrator)) {
    $powershellPath = Get-PowerShellExecutable
    if ($powershellPath) {
        try {
            Start-Process -FilePath $powershellPath -Verb RunAs -ArgumentList @(
                '-NoProfile'
                '-ExecutionPolicy'
                'Bypass'
                '-STA'
                '-File'
                "`"$PSCommandPath`""
            ) -WorkingDirectory $PSScriptRoot
            exit
        }
        catch {
            Write-Error "Kansa GUI must be run as Administrator. $($_.Exception.Message)"
            exit 1
        }
    }

    Write-Error 'Kansa GUI must be run as Administrator, but no PowerShell executable could be found for elevation.'
    exit 1
}

if ($Host.Runspace.ApartmentState -ne 'STA') {
    $powershellPath = Get-PowerShellExecutable
    if ($powershellPath) {
        Start-Process -FilePath $powershellPath -Verb RunAs -ArgumentList @(
            '-NoProfile'
            '-ExecutionPolicy'
            'Bypass'
            '-STA'
            '-File'
            "`"$PSCommandPath`""
        ) -WorkingDirectory $PSScriptRoot
        exit
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:ScriptRoot = $PSScriptRoot
if (-not $script:ScriptRoot) {
    $script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Show-KansaError {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        'Error!',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Confirm-KansaAdministrator {
    if (Test-IsAdministrator) {
        return $true
    }

    Show-KansaError 'Kansa GUI must be running as Administrator. Close this window and launch it again with elevated privileges.'
    return $false
}

function Get-SavedConfigNames {
    $savedConfigsPath = Join-Path $script:ScriptRoot 'ToolBox\SavedConfigs'
    if (-not (Test-Path -LiteralPath $savedConfigsPath -PathType Container)) {
        return @()
    }

    Get-ChildItem -LiteralPath $savedConfigsPath -Directory -Force |
        Sort-Object -Property Name |
        Select-Object -ExpandProperty Name
}

function Update-SavedConfigDropdown {
    if (-not $script:FolderListCombo) {
        return
    }

    $selectedConfig = $script:FolderListCombo.Text
    $savedConfigNames = @(Get-SavedConfigNames)

    $script:FolderListCombo.BeginUpdate()
    try {
        $script:FolderListCombo.Items.Clear()

        if ($savedConfigNames.Count -gt 0) {
            [void]$script:FolderListCombo.Items.AddRange([object[]]$savedConfigNames)

            if ($savedConfigNames -contains $selectedConfig) {
                $script:FolderListCombo.Text = $selectedConfig
            }
            else {
                $script:FolderListCombo.SelectedIndex = 0
            }
        }
        else {
            $script:FolderListCombo.Text = ''
        }
    }
    finally {
        $script:FolderListCombo.EndUpdate()
    }
}

function Initialize-KansaResultsPath {
    $resultsPath = Join-Path $script:ScriptRoot 'Results'
    if (-not (Test-Path -LiteralPath $resultsPath -PathType Container)) {
        New-Item -Path $resultsPath -ItemType Directory -Force | Out-Null
    }
}

function Get-KansaImagePath {
    $imageDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Temp'
    $installedImagePath = Join-Path $imageDirectory 'kansa.jpg'
    $candidatePaths = @(
        (Join-Path $script:ScriptRoot 'kansa.jpg'),
        (Join-Path $script:ScriptRoot 'ToolBox\MoreKansaScripts\kansa.jpg')
    )

    $sourceImagePath = $candidatePaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $sourceImagePath) {
        return $null
    }

    try {
        if (-not (Test-Path -LiteralPath $imageDirectory -PathType Container)) {
            New-Item -Path $imageDirectory -ItemType Directory -Force | Out-Null
        }

        Copy-Item -LiteralPath $sourceImagePath -Destination $installedImagePath -Force
        return $installedImagePath
    }
    catch {
        return $sourceImagePath
    }
}

Initialize-KansaResultsPath

function Move-KansaConfigs {
    $selectedConfig = $FolderListCombo.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($selectedConfig)) {
        Show-KansaError 'Error: Please select a Module Configuration from the Drop Down Menu.'
        return $false
    }

    $selectedConfigPath = Join-Path $script:ScriptRoot "ToolBox\SavedConfigs\$selectedConfig"
    $sourceModulesConfig = Join-Path $selectedConfigPath 'Modules.conf'
    $sourceAnalysisConfig = Join-Path $selectedConfigPath 'Analysis.conf'
    $destinationModulesConfig = Join-Path $script:ScriptRoot 'Modules\Modules.conf'
    $destinationAnalysisConfig = Join-Path $script:ScriptRoot 'Analysis\Analysis.conf'

    if (-not (Test-Path -LiteralPath $sourceModulesConfig -PathType Leaf)) {
        Show-KansaError "Error: File Does not Exist.`r`nSelect another Module Configuration from the Drop Down Menu."
        return $false
    }

    try {
        Copy-Item -LiteralPath $sourceModulesConfig -Destination $destinationModulesConfig -Force

        if (Test-Path -LiteralPath $sourceAnalysisConfig -PathType Leaf) {
            Copy-Item -LiteralPath $sourceAnalysisConfig -Destination $destinationAnalysisConfig -Force
        }

        return $true
    }
    catch {
        Show-KansaError "Error: Unable to move selected configuration files.`r`n$($_.Exception.Message)"
        return $false
    }
}

function Start-KansaRunner {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    if (-not (Confirm-KansaAdministrator)) {
        return
    }

    $runnerPath = Join-Path $script:ScriptRoot $ScriptName
    if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
        Show-KansaError "Error: Could not find $ScriptName."
        return
    }

    $powershellPath = Get-PowerShellExecutable
    if (-not $powershellPath) {
        Show-KansaError 'Error: Could not find powershell.exe.'
        return
    }

    try {
        Start-Process -FilePath $powershellPath -ArgumentList @(
            '-NoExit'
            '-NoProfile'
            '-ExecutionPolicy'
            'Bypass'
            '-File'
            "`"$runnerPath`""
        ) -WorkingDirectory $script:ScriptRoot -Verb RunAs
    }
    catch {
        Show-KansaError "Error: Unable to start Kansa.`r`n$($_.Exception.Message)"
    }
}

function Start-Kansa {
    if ($RemoteHostRadio.Checked) {
        if (-not (Move-KansaConfigs)) {
            return
        }

        $hostListPath = Join-Path $script:ScriptRoot 'hostlist.txt'

        if ($SingleHostRadio.Checked) {
            $hostName = $EnterHostName.Text.Trim()

            if ([string]::IsNullOrWhiteSpace($hostName) -or
                $hostName -eq 'Enter Host Name' -or
                $hostName -eq 'EnterHostName') {
                Show-KansaError 'Error: Please Enter A Valid Host Name.'
                return
            }

            try {
                if (Test-Path -LiteralPath $hostListPath -PathType Leaf) {
                    Remove-Item -LiteralPath $hostListPath -Force
                }

                Set-Content -LiteralPath $hostListPath -Value $hostName -Encoding ASCII
                Start-Sleep -Milliseconds 500
                Start-KansaRunner 'Run-KansaRemoteHost.ps1'
            }
            catch {
                Show-KansaError "Error: Unable to create hostlist.txt.`r`n$($_.Exception.Message)"
            }

            return
        }

        if ($HostListRadio.Checked) {
            $selectedHostList = $SelectHostList.Text.Trim()
            $placeholderText = 'Click Browse & Select a Host List'

            if ([string]::IsNullOrWhiteSpace($selectedHostList) -or
                $selectedHostList -eq $placeholderText -or
                -not (Test-Path -LiteralPath $selectedHostList -PathType Leaf)) {
                Show-KansaError 'Error: Please Click the "Browse" Button to Select a Host List.'
                return
            }

            try {
                if ((Test-Path -LiteralPath $hostListPath -PathType Leaf) -and
                    ([System.IO.Path]::GetFullPath($selectedHostList) -ne [System.IO.Path]::GetFullPath($hostListPath))) {
                    Remove-Item -LiteralPath $hostListPath -Force
                }

                Copy-Item -LiteralPath $selectedHostList -Destination $hostListPath -Force
                Start-Sleep -Milliseconds 500
                Start-KansaRunner 'Run-KansaRemoteHost.ps1'
            }
            catch {
                Show-KansaError "Error: Unable to copy the selected host list.`r`n$($_.Exception.Message)"
            }

            return
        }

        Show-KansaError 'Performing IR on a Remote host requires you to select "Single Host" or "Host List".'
        return
    }

    if ($LocalComputerRadio.Checked) {
        if (Move-KansaConfigs) {
            Start-KansaRunner 'Run-KansaLocal.ps1'
        }
        return
    }

    Show-KansaError "Now You've done it."
}

function Browse-HostList {
    $savedHostListsPath = Join-Path $script:ScriptRoot 'ToolBox\SavedHostLists'
    if (-not (Test-Path -LiteralPath $savedHostListsPath -PathType Container)) {
        $savedHostListsPath = $script:ScriptRoot
    }

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = 'Open file - *.txt'
    $openFileDialog.InitialDirectory = $savedHostListsPath
    $openFileDialog.Filter = 'Text File (*.txt)|*.txt'
    $openFileDialog.CheckFileExists = $true
    $openFileDialog.Multiselect = $false

    if ($openFileDialog.ShowDialog($Form1) -eq [System.Windows.Forms.DialogResult]::OK) {
        $SelectHostList.Text = $openFileDialog.FileName
    }
    else {
        Show-KansaError "No File Chosen.`r`nPlease Select a Text File ( *.txt )"
    }
}

$Form1 = New-Object System.Windows.Forms.Form
$Form1.Text = 'Kansa - Incident Response'
$Form1.ClientSize = New-Object System.Drawing.Size(401, 318)
$Form1.StartPosition = 'CenterScreen'
$Form1.FormBorderStyle = 'FixedDialog'
$Form1.MaximizeBox = $false
$DefaultGuiFont = New-Object System.Drawing.Font('MS Sans Serif', 8.25, [System.Drawing.FontStyle]::Regular)
$GroupHeaderFont = New-Object System.Drawing.Font('MS Sans Serif', 10, [System.Drawing.FontStyle]::Bold)
$Form1.Font = $DefaultGuiFont

$Group1 = New-Object System.Windows.Forms.GroupBox
$Group1.Text = 'Incident Response Location'
$Group1.Font = $GroupHeaderFont
$Group1.Location = New-Object System.Drawing.Point(8, 8)
$Group1.Size = New-Object System.Drawing.Size(385, 193)
$Form1.Controls.Add($Group1)

$LocalComputerRadio = New-Object System.Windows.Forms.RadioButton
$LocalComputerRadio.Text = "Local Computer:  $env:COMPUTERNAME"
$LocalComputerRadio.Font = $DefaultGuiFont
$LocalComputerRadio.Location = New-Object System.Drawing.Point(8, 22)
$LocalComputerRadio.Size = New-Object System.Drawing.Size(281, 17)
$Group1.Controls.Add($LocalComputerRadio)

$RemoteHostRadio = New-Object System.Windows.Forms.RadioButton
$RemoteHostRadio.Text = 'Remote Host - Requires PS Remoting is Enabled on Remote Host'
$RemoteHostRadio.Font = $DefaultGuiFont
$RemoteHostRadio.Location = New-Object System.Drawing.Point(8, 54)
$RemoteHostRadio.Size = New-Object System.Drawing.Size(365, 17)
$RemoteHostRadio.Checked = $true
$Group1.Controls.Add($RemoteHostRadio)

$Group3 = New-Object System.Windows.Forms.GroupBox
$Group3.Text = ''
$Group3.Font = $DefaultGuiFont
$Group3.Location = New-Object System.Drawing.Point(16, 80)
$Group3.Size = New-Object System.Drawing.Size(353, 105)
$Group1.Controls.Add($Group3)

$SingleHostRadio = New-Object System.Windows.Forms.RadioButton
$SingleHostRadio.Text = 'Single Host'
$SingleHostRadio.Font = $DefaultGuiFont
$SingleHostRadio.Location = New-Object System.Drawing.Point(16, 16)
$SingleHostRadio.Size = New-Object System.Drawing.Size(81, 17)
$Group3.Controls.Add($SingleHostRadio)

$HostListRadio = New-Object System.Windows.Forms.RadioButton
$HostListRadio.Text = 'Host List'
$HostListRadio.Font = $DefaultGuiFont
$HostListRadio.Location = New-Object System.Drawing.Point(16, 48)
$HostListRadio.Size = New-Object System.Drawing.Size(73, 17)
$Group3.Controls.Add($HostListRadio)

$EnterHostName = New-Object System.Windows.Forms.TextBox
$EnterHostName.Text = 'Enter Host Name'
$EnterHostName.Font = $DefaultGuiFont
$EnterHostName.Location = New-Object System.Drawing.Point(104, 16)
$EnterHostName.Size = New-Object System.Drawing.Size(233, 21)
$Group3.Controls.Add($EnterHostName)

$SelectHostList = New-Object System.Windows.Forms.TextBox
$SelectHostList.Text = 'Click Browse & Select a Host List'
$SelectHostList.Font = $DefaultGuiFont
$SelectHostList.Location = New-Object System.Drawing.Point(104, 48)
$SelectHostList.Size = New-Object System.Drawing.Size(233, 21)
$SelectHostList.ReadOnly = $true
$SelectHostList.TextAlign = 'Center'
$Group3.Controls.Add($SelectHostList)

$BrowseHostList = New-Object System.Windows.Forms.Button
$BrowseHostList.Text = 'Browse'
$BrowseHostList.Font = $DefaultGuiFont
$BrowseHostList.Location = New-Object System.Drawing.Point(103, 72)
$BrowseHostList.Size = New-Object System.Drawing.Size(139, 25)
$BrowseHostList.Add_Click({ Browse-HostList })
$Group3.Controls.Add($BrowseHostList)

$Group2 = New-Object System.Windows.Forms.GroupBox
$Group2.Text = 'Module Configuration'
$Group2.Font = $GroupHeaderFont
$Group2.Location = New-Object System.Drawing.Point(8, 208)
$Group2.Size = New-Object System.Drawing.Size(385, 55)
$Form1.Controls.Add($Group2)

$script:FolderListCombo = New-Object System.Windows.Forms.ComboBox
$script:FolderListCombo.Font = $DefaultGuiFont
$script:FolderListCombo.Location = New-Object System.Drawing.Point(16, 24)
$script:FolderListCombo.Size = New-Object System.Drawing.Size(353, 25)
$script:FolderListCombo.DropDownStyle = 'DropDown'
$script:FolderListCombo.MaxDropDownItems = 30
$script:FolderListCombo.DropDownHeight = 420
$script:FolderListCombo.AutoCompleteMode = 'SuggestAppend'
$script:FolderListCombo.AutoCompleteSource = 'ListItems'
Update-SavedConfigDropdown
$Group2.Controls.Add($script:FolderListCombo)

$StartKansa = New-Object System.Windows.Forms.Button
$StartKansa.Text = 'Start Kansa'
$StartKansa.Font = $DefaultGuiFont
$StartKansa.Location = New-Object System.Drawing.Point(262, 278)
$StartKansa.Size = New-Object System.Drawing.Size(131, 25)
$StartKansa.Add_Click({ Start-Kansa })
$Form1.Controls.Add($StartKansa)

$imagePath = Get-KansaImagePath
if ($imagePath) {
    $KansaPicture = New-Object System.Windows.Forms.PictureBox
    $KansaPicture.Location = New-Object System.Drawing.Point(8, 262)
    $KansaPicture.Size = New-Object System.Drawing.Size(240, 57)
    $KansaPicture.SizeMode = 'StretchImage'
    $KansaPicture.ImageLocation = $imagePath
    $Form1.Controls.Add($KansaPicture)
}

$Form1.Add_Shown({ Update-SavedConfigDropdown })

[void]$Form1.ShowDialog()
