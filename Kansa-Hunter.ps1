<#
.Synopsis
   Kansa-Hunter.ps1 
   Repetitively checks for an active WinRM connection to a desired host.
   Once a connection is discovered, Kansa-Hunter will run IR against the targeted host. 

.DESCRIPTION
   Kansa-Hunter.ps1 by:  Aj  
   Version 0.2 - BETA VERSION    
   Last modified: 7.08.2021        
 
   Hunts down elusive hosts to perform IR via Kansa. 
   Pro Tip: Best ran from VM/VDI with continuous uptime and network access to desired target. 

.EXAMPLE
   Kansa-Hunter.ps1 -Target hostName [-Seconds] 300 [-Modules] pathtoModule.config [-emailAlert] user@domain.com    
.EXAMPLE
   Kansa-Hunter.ps1 -Target PC123456 -Seconds 300 -Modules .\ToolBox\SavedConfigs\01_SOC_BASIC_IR\Modules.conf

.LINK
          
#>

[CmdletBinding()]
param (	
        # Domain to scan.
        [Parameter(Mandatory=$true)]
        [string]$target, 
        [Parameter(Mandatory=$false)]
        [Int32]$seconds = 200, 
        [string]$module = ".\ToolBox\SavedConfigs\01_SOC_BASIC_IR\Modules.conf", 
        [string]$emailAlertAddress = ""  # <<-- ADD Email Address: "<user@domain.com>" for alerts via Outlook, or use switches 
)        

#Set Second equal to the delay time in seconds  
$delaySeconds = $seconds

#get scripts current location 
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#Make the "Hunters" directory if it does not exist
$huntersDir = "$scriptPath\Results\Hunters"
if (!(Test-path $huntersDir)) {clear-host;Write-host "Creating Directory:";New-Item -ItemType Directory -Force -Path $huntersDir; Start-Sleep -Seconds 1;}
#Make the target Directory 
if (!(Test-path "$huntersDir\KansaHunter_$target")) {clear-host; Write-host "Creating Directory:";New-Item -ItemType Directory -Force -Path "$huntersDir\KansaHunter_$target"; Start-Sleep -Seconds 1;}
if (!(Test-path "$huntersDir\KansaHunter_$target\Results")) {clear-host; Write-host "Creating Directory:";New-Item -ItemType Directory -Force -Path "$huntersDir\KansaHunter_$target\Results";}

clear-host; Write-host "Creating Hunter."; 
Write-host "Please wait."

#Copy Files to their proper directories 
Copy-Item -path "$scriptPath\Analysis" -destination "$huntersDir\KansaHunter_$target\" -Recurse
Copy-Item -path "$scriptPath\Modules" -destination "$huntersDir\KansaHunter_$target\" -Recurse
Copy-Item -path "$scriptPath\ToolBox" -destination "$huntersDir\KansaHunter_$target\" -Recurse
Copy-Item -path "$scriptPath\7z.exe" -destination "$huntersDir\KansaHunter_$target\" 
Copy-Item -path "$scriptPath\7z.dll" -destination "$huntersDir\KansaHunter_$target\" 
Copy-Item -path "$scriptPath\kansa.ps1" -destination "$huntersDir\KansaHunter_$target\" 
Copy-Item -path "$scriptPath\Modules\KansaHunter\Hunter.ps1" -destination "$huntersDir\KansaHunter_$target\"
Copy-Item -path "$scriptPath\Run-KansaRemoteHost.ps1" -destination "$huntersDir\KansaHunter_$target\" 
Copy-Item -path "$scriptPath\kansa.ps1" -destination "$huntersDir\KansaHunter_$target\" 

$batchFile = "$huntersDir\KansaHunter_$target\RunKansaHunter_$target.bat"

#Batch File 
Function makeBatchFile() {
    Add-Content -Path $batchFile "@echo off "
    Add-Content -Path $batchFile " "
    Add-Content -Path $batchFile ":: BatchGotAdmin"
    Add-Content -Path $batchFile ":-------------------------------------"
    Add-Content -Path $batchFile "REM  --> Check for permissions"
    Add-Content -Path $batchFile "IF `'%PROCESSOR_ARCHITECTURE%`' EQU `'amd64`' ("
    Add-Content -Path $batchFile "   >nul 2>&1 `"%SYSTEMROOT%\SysWOW64\icacls.exe`" `"%SYSTEMROOT%\SysWOW64\config\system`""
    Add-Content -Path $batchFile " ) ELSE ("
    Add-Content -Path $batchFile "   >nul 2>&1 `"%SYSTEMROOT%\system32\icacls.exe`" `"%SYSTEMROOT%\system32\config\system`""
    Add-Content -Path $batchFile ")"
    Add-Content -Path $batchFile " "
    Add-Content -Path $batchFile "REM --> If error flag set, we do not have admin."
    Add-Content -Path $batchFile "if `'%errorlevel%`' NEQ `'0`' ("
    Add-Content -Path $batchFile "    echo Requesting administrative privileges..."
    Add-Content -Path $batchFile "    goto UACPrompt"
    Add-Content -Path $batchFile ") else ( goto gotAdmin )"
    Add-Content -Path $batchFile " "
    Add-Content -Path $batchFile ":UACPrompt"
    Add-Content -Path $batchFile "    echo Set UAC = CreateObject^(`"Shell.Application`"^) > `"%temp%\getadmin.vbs`""
    Add-Content -Path $batchFile "    set params = %*:`"=`"`""
    Add-Content -Path $batchFile "    echo UAC.ShellExecute `"cmd.exe`", `"/c %~s0 %params%`", `"`", `"runas`", 1 >> `"%temp%\getadmin.vbs`""
    Add-Content -Path $batchFile " " 
    Add-Content -Path $batchFile "    `"%temp%\getadmin.vbs`""
    Add-Content -Path $batchFile "     del `"%temp%\getadmin.vbs`""
    Add-Content -Path $batchFile "     exit /B"
    Add-Content -Path $batchFile " "
    Add-Content -Path $batchFile ":gotAdmin"
    Add-Content -Path $batchFile "    pushd `"%CD%`""
    Add-Content -Path $batchFile "    CD /D `"%~dp0`""
    Add-Content -Path $batchFile ":--------------------------------------"
    Add-Content -Path $batchFile " "
    If (!([string]::IsNullOrEmpty($emailAlertAddress) )){
        Add-Content -Path $batchFile "cmd.exe /c Powershell.exe -executionpolicy bypass -Command  `"%~dp0Hunter.ps1 -target \`"$target\`" -seconds \`"$delaySeconds\`" -kansaModule \`"$module\`" -emailAlert \`"$emailAlertAddress\`"`""
    }Else{
        Add-Content -Path $batchFile "cmd.exe /c Powershell.exe -executionpolicy bypass -Command  `"%~dp0Hunter.ps1 -target \`"$target\`" -seconds \`"$delaySeconds\`" -kansaModule \`"$module\`" `""
    }    
    Add-Content -Path $batchFile " "
} #END Batch File Func  
makeBatchFile  
# Change working directory to the newly created KansaHunter_* dir 
Set-Location "$huntersDir\KansaHunter_$target\"
# Launch Batch File to run Kansa Hunter 
& $batchFile
