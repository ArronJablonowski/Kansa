<#
.Synopsis
   Hunter.ps1 
   Repetitively checks for an active WinRM connection to a desired host.
   Once a connection is discovered, Hunter will run IR against the targeted host. 

.DESCRIPTION
   Hunter.ps1 by:  Aj  
   Version 0.1 - BETA VERSION    
   Last modified: 6.14.2026     
 
   Hunts down elusive hosts to perform IR via Kansa. 
   Pro Tip: Best ran from VM with continuous uptime and network access to desired target. 

.EXAMPLE
   Hunter.ps1 -Target hostName -Seconds 5 -kansaModules pathtoModule.config [-emailAlert] user@domain.com    
.EXAMPLE
   Hunter.ps1 -Target HOST123456 -Seconds 300 -kansaModules .\ToolBox\SavedConfigs\01_SOC_BASIC_IR\Modules.conf

.LINK
          
#>

[CmdletBinding()]
param (	
        # Domain to scan.
        [Parameter(Mandatory=$true)]
        [string]$target, [string]$seconds, [string]$kansaModule,
        # Set time in minutes to check network
        [Parameter(Mandatory=$false)]
        [string]$emailAlert 
)
#ASCII
cls
Write-host ""
Write-host "    __ __                          __  __            __              "
Write-host "   / //_/_____ ___   ____ _______ / / / /_  __ ___  / /____   _______ "
Write-host "  / ,< / __  / __ \/ ___/ __  /  / /_/ / / / / __ \/ __/ _ \/ ___/   "
Write-host " / /| / /_/ / / / (__  ) /_/ /  / __  / /_/ / / / / /_/  __/ /       "
Write-host "/_/ |_\__,_/_/ /_/____/\__,_/  /_/ /_/\__,_/_/ /_/\__/\___/_/ beta   "
Write-host ""
#Error Checking for required parameters 
If ([string]::IsNullOrEmpty($target)){Write-Host "Kansa Hunter is missing required parameters. Please see Examples: Get-Help .\Kansa-Hunter.ps1 -Examples"; Get-help ./Kansa-Hunter.ps1 -Examples; exit}
If ([string]::IsNullOrEmpty($seconds)){Write-Host "Kansa Hunter is missing required parameters. Please see Examples: Get-Help .\Kansa-Hunter.ps1 -Examples"; Get-help ./Kansa-Hunter.ps1 -Examples; exit}
If ([string]::IsNullOrEmpty($kansaModule)){Write-Host "Kansa Hunter is missing required parameters. Please see Examples: Get-Help .\Kansa-Hunter.ps1 -Examples"; Get-help ./Kansa-Hunter.ps1 -Examples; exit}
Write-host "       ____          ____"
Write-host "      |oooo|        |oooo|"
Write-host "      |oooo| .----. |oooo|"
Write-host "      |Oooo|/\_||_/\|oooO|"
Write-host "       '---' / __ \ '---'"
Write-host "      ,/ |#|/\/__\/\|#| \,"
Write-host "     /  \|#|| |/\| ||#|/  \"
Write-host "    / \_/|_|| |/\| ||_|\_/ \"
Write-host "   |_\/    o\=----=/o    \/_|"
Write-host "   <_>      |=\__/=|      <_>"
Write-host "   <_>      |------|      <_>"
Write-host "   | |   ___|======|___   | |"
Write-host "  //\\  / |O|======|O| \  //\\"
Write-host "  |  |  | |O+------+O| |  |  |"
Write-host "  |\/|  \_+/        \+_/  |\/|"
Write-host "  \__/  _|||        |||_  \__/"
Write-host "        | ||        || |"
Write-host "       [==|]        [|==]"
Write-host "       [===]        [===]"
Write-host "        >_<          >_<"
Write-host "       || ||        || ||"
Write-host "       || ||        || ||"
Write-host "       || ||        || ||  "
Write-host "     __|\_/|__    __|\_/|__"
Write-host "    /___n_n___\  /___n_n___\"
Write-host "|==============================|"
#end ASCII 

##### Global Vars #####
$testConnectionFail = 0 
$testedTotal = 0 
$liveHostCounter = 0
$UNCPath #hold path to make UNC link in email 
#Holds path to batch file to relaunch Kansa Hunter 
$batchFile = ".\RunKansaHunter_$target.bat" 
#Holds path to VBS Email Script 
$EmailScriptPath = "C:\ProgramData\TestEmail.vbs" 
#trigger file - If exists then stop while loop 
$triggerFile = './targetFound.txt'
If(Test-Path $triggerFile){rm $triggerFile}
#logfile
$logFile = './ActivityLog_HostHunter.txt'
If(Test-Path $logFile){rm $logFile}

#Remove old batc files 
rm ".\RunKansaHunter_*.bat"

#Check if running as admin 
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$RunAsAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-host " " 
Write-Host "     Verified Admin: $RunAsAdmin"
If(($RunAsAdmin -eq $false)){
    Write-Host "You must run this script as an Admin. Terminating script."    
    Exit
}
#Sleep 
Start-sleep -seconds 1
Write-Host "     Target: $target" 
Start-sleep -seconds 1
Write-Host "     Seconds: $seconds"
Start-sleep -seconds 1
Write-Host "     KansaModule: $kansaModule"
Start-sleep -seconds 1
If (!([string]::IsNullOrEmpty($emailAlert) )){
    Write-Host "     Email Alert: $emailAlert"
}else {
    Write-Host "     Email Alert: none"
}
Start-Sleep -Seconds 2

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
    If (!([string]::IsNullOrEmpty($emailAlert) )){
        Add-Content -Path $batchFile "cmd.exe /k Powershell.exe -executionpolicy bypass -Command  `"%~dp0Hunter.ps1 -target \`"$target\`" -seconds \`"$seconds\`" -kansaModule \`"$kansaModule\`" -emailAlert \`"$emailAlert\`"`""
    }Else{
        Add-Content -Path $batchFile "cmd.exe /k Powershell.exe -executionpolicy bypass -Command  `"%~dp0Hunter.ps1 -target \`"$target\`" -seconds \`"$seconds\`" -kansaModule \`"$kansaModule\`" `""
    }    
    Add-Content -Path $batchFile " "
} #END Batch File Func 
#Call MakeBatchFile Func 
makeBatchFile 

#### EMAIL FUNCTION ####
function sendemailalert () {
    If(!([string]::IsNullOrEmpty($emailAlert))){
        #Setup scheduled task to run Outlook as standard user         
        #Check if scheduled task is registered. If so delete it. 
        $taskName = "IREmail"
        $taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }
        if($taskExists) {
            Write-Host "Left over Scheduled Task discovered from. Deleting..."
            Unregister-ScheduledTask -TaskName "$taskname" -Confirm:$false  
            Start-Sleep -Seconds 5
        }
        #Outlook.exe
        $ProcessActive = Get-Process outlook -ErrorAction SilentlyContinue 
        function Start-Outlook {
            [CmdletBinding()] 
            Param ()
            if (!($ProcessActive -eq $null)){
            #if (Get-Process | Where-Object name -eq outlook) {
                Write-host '' 
                Write-host '>> Outlook is Already Running.'
                Write-Host '------------------------------'
                Write-Host " --> No Action Needed."
                # Stop-Process -name OUTLOOK -Force #test code kills outlook 
                start-sleep -Seconds 2
                }
            else {
                $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE\'
                if (!(Test-Path -Path $key)) {
                    throw 'Path to Outlook executable not found.'
                } else {
                    $exe = (Get-ItemProperty -Path $key).'(default)'
                    if (Test-Path -Path $exe) {
                        Write-host '' 
                        Write-host '' 
                        Write-host '>> Starting Outlook application...'
                        Write-Host '----------------------------------'
                        Write-Host " --> Sending Email Alert to $emailAlert"
                        Write-Host " --> Script has Admin Priveleges: $RunasAdmin"
                        Write-Host " --> Scheduling task to run Outlook as standard user: $env:UserName"
                        #Invoke-Item -Path  $exe #Outlook is handled by VBS script - so this is not needed           
                        Start-Sleep -Seconds 5
                    } else {
                        throw 'Outlook executable not found.'
                    }
                }
            }
        }
        Start-Outlook 
        
        #./TestEmail.vbs
        $currentDetectionTime = Get-Date -Format G
        #$scriptPathReplace = split-path -parent $MyInvocation.MyCommand.Definition
        #$UNCPath = $scriptPathReplace.Replace(':','$')        
        If(Test-Path "$EmailScriptPath"){rm $EmailScriptPath;Start-Sleep -seconds 2;}
        #$logFileAttchment = $logFile.FullName
        #Write-Host $logFileAttchment
        $logFileAttchment = "C:\ProgramData\KansaHunterLog_$target.txt"
        Copy-Item $logFile $logFileAttchment -Force

        #VBS to send email as a standard user (not Admin like the scripts execution)
        Add-Content -Path $EmailScriptPath "Dim FromAddress"
        Add-Content -Path $EmailScriptPath "Dim MessageSubject"
        Add-Content -Path $EmailScriptPath "Dim MessageBody"
        Add-Content -Path $EmailScriptPath "Dim ol, ns, newMail"
        Add-Content -Path $EmailScriptPath " "
        Add-Content -Path $EmailScriptPath "MessageSubject = `"Kansa detected $target on the network and started performing IR.`""
        Add-Content -Path $EmailScriptPath "MessageBody =`"<HTML><HEAD><style>h1 {background-color:#009D57; color:white; text-align: center;}table, td {border-collapse: collapse; border: 1px solid #4F81BD;} p {color:black}</style></HEAD><BODY><p>  </p><table width = 500><tr><td colspan = 2><h1> &#9752; Information Security &#9752; </h1></td></tr><tr><td><p>Discovered Host </p></td><td><p> $target  </p></td></tr><tr><td><p>Discovery Time </p></td><td><p> $currentDetectionTime </p></td></tr><tr><td><p>Host that Discovered $target </p></td><td><p> $env:COMPUTERNAME </p></td></tr><tr><td><p>Kansa IR UNC Path </p></td><td><p> \\$env:COMPUTERNAME\$UNCPath\ </p></td></tr>  <tr><td><p>Kansa IR Module Ran </p></td><td><p> $kansaModule </p></td></tr></table><P>Kansa was able to detect $target on the network and has started to perform IR on the host. See the above UNC path for the results.</P><p>- Kansa </p><hr></BODY></HTML>`""
        Add-Content -Path $EmailScriptPath "Set ol = WScript.CreateObject(`"Outlook.Application`") "
        Add-Content -Path $EmailScriptPath "Set ns = ol.getNamespace(`"MAPI`") "
        Add-Content -Path $EmailScriptPath "ns.logon `"`",`"`",false,false"
        Add-Content -Path $EmailScriptPath "Set newMail = ol.CreateItem(olMailItem) "
        Add-Content -Path $EmailScriptPath "newMail.Subject = MessageSubject "
        Add-Content -Path $EmailScriptPath "newMail.HtmlBody = MessageBody & vbCrLf "
        Add-Content -Path $EmailScriptPath "newMail.Recipients.Add(`"$emailAlert`")"
        Add-Content -Path $EmailScriptPath "newMail.Attachments.Add(`"$logFileAttchment`")"
        Add-Content -Path $EmailScriptPath " "
        Add-Content -Path $EmailScriptPath "newMail.Send"
        Add-Content -Path $EmailScriptPath "Set ol = Nothing"
        #Scheduled Task 
        Write-host ""
        Write-host ""
        Write-host ">> Scheduling Task to send Email Alert as Non-Admin"
        write-host "---------------------------------------------------"
        $A = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "$EmailScriptPath"
        $T = New-ScheduledTaskTrigger -AtLogon #just a place holder - executio will happen below 
        $user = "$env:UserDomain\$env:UserName"
        $P = New-ScheduledTaskPrincipal $user
        #$S = New-ScheduledTaskSettingsSet
        $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T #-Settings $S 
        Register-ScheduledTask -TaskName "IREmailer" -InputObject $D  
        Start-Sleep -seconds 2 
        Start-ScheduledTask -TaskName "IREmailer"
        Start-Sleep -seconds 10
        Write-host ""
        Write-host ">> Deleting Scheduled Task. "
        write-host "---------------------------"
        Unregister-ScheduledTask -TaskName "IREmailer" -Confirm:$false 
        Write-host " --> Scheduled Task Deleted"
        Write-host " "
        If(Test-Path "$logFileAttchment"){Start-Sleep -seconds 2;rm $logFileAttchment;}
       # Exit 
    }#End if $Email
} #End SendEmailAlert Func

# Just a formatting space 
Write-Host ''

#Start Checking for Host on network 
#Host not found   
while(!(Test-Path $triggerFile -ErrorAction SilentlyContinue)){  
    #attempt number 
    $testedTotalPlusOne = $testedTotal + 1 

    #Check for active WinRm session        
    $testResults = $null
    $testResults = Test-WSMan -ComputerName $target -Authentication default -ErrorAction SilentlyContinue
    #Check if able to connecto via WinRM
    if($null -ne $testResults){        
        $currentDetectionTime = Get-Date -Format G
        $currentStatus =  " $testedTotalPlusOne [Target: $target] - [Time: $currentDetectionTime] - [Status: Running Kansa]"
        Write-Host $currentStatus
        Add-Content -Path $logFile $currentStatus
        $liveHostCounter = $liveHostCounter +1 

        #Run Kanas & Set Trigger File  - test code 
        Write-Host "Detected host: $target - Running Kansa"
        Write-Host "" 
        
        If ( (!([string]::IsNullOrEmpty($target))) -and (!([string]::IsNullOrEmpty($kansaModule)))){
            $hostlist = ".\Hostlist.txt"
            If(Test-Path $hostlist){
                rm $hostlist
            }
            Add-Content -Path $hostlist $target 
            If(Test-Path $kansaModule){
                $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
                Copy-Item $kansaModule -Destination "$scriptPath\Modules\Modules.conf" -Force
                #\Analysis\Analysis.conf
                $analysisModule = $kansaModule.Replace('Modules.conf','Analysis.conf')
                Copy-Item $analysisModule -Destination "$scriptPath\Analysis\Analysis.conf" -Force
               
                $UNCPath = $scriptPath.Replace(':','$')
                
                ### RUN KANSA ###
                #================
                .\Run-KansaRemoteHost.ps1 
                sendemailalert

                Write-host ""
                Write-host ">> Running Cleanup Jobs "
                write-host "---------------------------"
                #rm ".\RunKansaHunter_*.bat"
                If(Test-Path $batchFile){rm $batchFile;} #remove Batch File after Email is sent 
                If(Test-Path $EmailScriptPath){rm $EmailScriptPath;} #Remove VBS email script after email is sent 
                If(Test-Path $triggerFile){rm $triggerFile}
                If(Test-Path $logFile){rm $logFile}
                If(Test-Path ./7z.dll){remove-item ./7z.dll -recurse -force}
                If(Test-Path ./7z.exe){remove-item ./7z.exe -recurse -force}
                If(Test-Path *.txt){remove-item *.txt -force}
                If(Test-Path ./Analysis){remove-item ./Analysis -recurse -force}
                If(Test-Path ./Modules){remove-item ./Modules -recurse -force}
                If(Test-Path ./ToolBox){remove-item ./ToolBox -recurse -force}
                rm *.ps1
                Write-host " --> Cleanup Complete."
                #Write-host " "
                # Write-host ""

                #Stop execution once host has been found and IR has been ran 
                Start-Sleep -Seconds 2 
                Exit
            }
        }
        #trigger file 
        Add-Content -path $triggerFile -Value $currentDetectionTime 
    }Else{ # treat the line as a domain
        $currentDetectionTime = Get-Date -Format G
        $currentStatus = " $testedTotalPlusOne [ Target: $target ] - [ Time: $currentDetectionTime ] - [ Status: No Active WinRM Sessions ]"
        Write-Host $currentStatus
        Add-Content -Path $logFile $currentStatus
        $testConnectionFail = $testConnectionFail + 1
    }
    $testedTotal = $testedTotal + 1

    #Sleep Timer to control how often the script checks for a host 
    Start-Sleep -Seconds $seconds 
}

#Cleanup 
If(Test-Path $triggerFile){rm $triggerFile}
