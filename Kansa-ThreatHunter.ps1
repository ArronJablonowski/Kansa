<#
.Synopsis
    Kansa-ThreatHunter.ps1 
   
.DESCRIPTION
    This Script will analyze a large set of Kansa Results  

.EXAMPLE
    make example 

.LINK
    Working with Powershell Keyfiles and Protecting Passwords Required by Script 
        https://www.altaro.com/msp-dojo/encrypt-password-powershell/

#>


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
        [Switch]$AllAnalysis,
    [Parameter(Mandatory=$False)]
        [Switch]$Autorunsc,
    [Parameter(Mandatory=$False)]
        [Switch]$BrowserAddonsView,
    [Parameter(Mandatory=$False)]
        [Switch]$BrowserHistoryView,
    [Parameter(Mandatory=$False)]
        [Switch]$CertStore,
    [Parameter(Mandatory=$False)]
        [Switch]$ChromeExtensionListing,
    [Parameter(Mandatory=$False)]
        [Switch]$DNSCache,
    [Parameter(Mandatory=$False)]
        [Switch]$FireFoxExtensionListing,
    [Parameter(Mandatory=$False)]
        [Switch]$Handle,
    [Parameter(Mandatory=$False)]
        [Switch]$Hotfix,
    [Parameter(Mandatory=$False)]
        [Switch]$IIS,
    [Parameter(Mandatory=$False)]
        [Switch]$InjectedThreads,
    [Parameter(Mandatory=$False)]
        [Switch]$LocalAdmins,
    [Parameter(Mandatory=$False)]
        [Switch]$LogFile,
    [Parameter(Mandatory=$False)]
        [Switch]$LogUserAssist,
    [Parameter(Mandatory=$False)]
        [Switch]$MappedDrives,
    [Parameter(Mandatory=$False)]
        [Switch]$Netstat,
    [Parameter(Mandatory=$False)]
        [Switch]$OutlookAddins,
    [Parameter(Mandatory=$False)]
        [Switch]$PrefetchListing,
    [Parameter(Mandatory=$False)]
        [Switch]$ProcsImgPath,
    [Parameter(Mandatory=$False)]
        [Switch]$ProcInfo,
    [Parameter(Mandatory=$False)]
        [Switch]$ProcWMI,
    [Parameter(Mandatory=$False)]
        [Switch]$Products,
    [Parameter(Mandatory=$False)]
        [Switch]$PSDotNetVersion,
    [Parameter(Mandatory=$False)]
        [Switch]$PSList,
    [Parameter(Mandatory=$False)]
        [Switch]$PSProfiles,
    [Parameter(Mandatory=$False)]
        [Switch]$RDPConnectionLogs,
    [Parameter(Mandatory=$False)]
        [Switch]$SchedTasks,
    [Parameter(Mandatory=$False)]
        [Switch]$SmbShare,
    [Parameter(Mandatory=$False)]
        [Switch]$StartupCommand,
    [Parameter(Mandatory=$False)]
        [Switch]$SvcAll,
    [Parameter(Mandatory=$False)]
        [Switch]$SvcFail,
    [Parameter(Mandatory=$False)]
        [Switch]$SvcTrigs,
    [Parameter(Mandatory=$False)]
        [Switch]$SysmonNetwork10080,
    [Parameter(Mandatory=$False)]
        [Switch]$SysmonProcess10080,
    [Parameter(Mandatory=$False)]
        [Switch]$Tasklistv,
    [Parameter(Mandatory=$False)]
        [Switch]$TempDirListing,
    [Parameter(Mandatory=$False)]
        [Switch]$UserQuery,
    [Parameter(Mandatory=$False)]
        [Switch]$WMIEvtConsumer,
    [Parameter(Mandatory=$False)]
        [Switch]$WMIEvtFilter,
    [Parameter(Mandatory=$False)]
        [Switch]$WMIFltConBind,
    [Parameter(Mandatory=$False)]
        [Switch]$WMILogicalDisk,
    [Parameter(Mandatory=$False)]
        [Switch]$WMIPhysicalMedia,
    [Parameter(Mandatory=$False)]
        [Switch]$WMISystemDrivers,
    [Parameter(Mandatory=$False)]
        [Switch]$AuditClearTextPasswordsTextCUsers,
    [Parameter(Mandatory=$False)]
        [Switch]$AuditClearTextPasswordsDocXls
        
)

# Hold the Runtime to append to folder name 
$Runtime = ([String] (Get-Date -Format yyyyMMddHHmmss))

# Add Log Parser to the system's path 
$env:Path += ";C:\Program Files (x86)\Log Parser 2.2\" 

$workDone = "0" # Place holder for ending message 
$Encoding="Unicode" # set encoding to Unicode 

#If "LogCollector" folder doesn't exist, create it 
$logCollectorDir = "$psscriptroot\LogCollector"     
If(!($logCollectorDir)){New-Item -path "$psscriptroot" -name "LogCollector" -itemType "directory"}

#Direcotry to Analyze ---- If "Reporting" folder doesn't exist, create it 
#$AnalysisDir = "$logCollectorDir\Analysis"
$AnalysisDir = "$logCollectorDir"
# If(!($AnalysisDir)){New-Item -path "$psscriptroot" -name "Analysis" -itemType "directory"}


function Get-Directives {
    <#
    .SYNOPSIS
    Returns a hashtable of directives found in the script
    Directives are used for two things:
    1) The BINDEP directive tells Kansa that a module depends on some 
    binary and what the name of the binary is. If Kansa is called with 
    -PushBin, the script will look in Modules\bin\ for the binary and 
    attempt to copy it to targets. Specify multiple BINDEPs by
    separating each path with a semi-colon (;).
    
    2) The DATADIR directive tells Kansa what the output path is for
    the given module's data so that if it is called with the -Analysis
    flag, the analysis scripts can find the data.
    TK Some collector output paths are dynamically generated based on
    arguments, so this breaks for analysis. Solve.
    #>
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$Module,
        [Parameter(Mandatory=$False,Position=1)]
            [Switch]$AnalysisPath
    )
        Write-Debug "Entering $($MyInvocation.MyCommand)"
        $Error.Clear()
        if ($AnalysisPath) {
            $Module = ".\Analysis\" + $Module
        }
    
        if (Test-Path($Module)) {
            
            $DirectiveHash = @{}
    
            Get-Content $Module | Select-String -CaseSensitive -Pattern "BINDEP|DATADIR" | Foreach-Object { $Directive = $_
                if ( $Directive -match "(^BINDEP|^# BINDEP) (.*)" ) {
                    $DirectiveHash.Add("BINDEP", $($matches[2]))
                }
                if ( $Directive -match "(^DATADIR|^# DATADIR) (.*)" ) {
                    $DirectiveHash.Add("DATADIR", $($matches[2])) 
                }
            }
            $DirectiveHash
        } else {
            "WARNING: Get-Directives was passed invalid module $Module." | Add-Content -Encoding $Encoding $ErrorLog
        }
}
    

function Get-Analysis {
    <#
    .SYNOPSIS
    Runs analysis scripts as specified in .\Analyais\Analysis.conf
    Saves output to AnalysisReports folder under the output path
    Fails silently, but logs errors to Error.log file
    #>
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$OutputPath,
        [Parameter(Mandatory=$True,Position=1)]
            [String]$StartingPath
    )
        Write-Debug "Entering $($MyInvocation.MyCommand)"
        $Error.Clear()
    
        if (Get-Command -Name "Logparser.exe") {
            $AnalysisScripts = @()
            $AnalysisScripts = Get-Content "$StartingPath\Analysis\Analysis.conf" | Foreach-Object { $_.Trim() } | Where-object { $_ -gt 0 -and (!($_.StartsWith("#"))) }
    
            # Add a date time function = var 
            $AnalysisOutPath = $OutputPath + "\Analysis_$Runtime\"
            [void] (New-Item -Path $AnalysisOutPath -ItemType Directory -Force)
    
            # Get our DATADIR directive
            $DirectivesHash  = @{}
            $AnalysisScripts | Foreach-Object { $AnalysisScript = $_
                $DirectivesHash = Get-Directives $AnalysisScript -AnalysisPath
                $DataDir = $($DirectivesHash.Get_Item("DATADIR"))
                Write-host "Data Dir: $DataDir"
                if ($DataDir) {                    
                    if (Test-Path "$OutputPath\$DataDir") {
                        
                        Push-Location
                        Set-Location "$OutputPath\$DataDir"
                        
                        Write-host "Running analysis script: ${AnalysisScript}"
                        $AnalysisFile = ((((($AnalysisScript -split "\\")[1]) -split "Get-")[1]) -split ".ps1")[0]
                        # As of this writing, all analysis output files are csv
                        & "$StartingPath\Analysis\${AnalysisScript}" | Set-Content -Encoding $Encoding ($AnalysisOutPath + $AnalysisFile + ".csv")
                        Pop-Location
                    } else {
                        Write-host "WARNING: Analysis: No data found for ${AnalysisScript}." #| Add-Content -Encoding $Encoding $ErrorLog
                        Continue
                    }
                } else {
                    Write-host "WARNING: Analysis script, .\Analysis\${AnalysisScript}, missing # DATADIR directive, skipping analysis." # | Add-Content -Encoding $Encoding $ErrorLog
                    Continue
                }        
            }
        } else {
            "Kansa could not find logparser.exe in path. Skipping Analysis." | Add-Content -Encoding $Encoding -$ErrorLog
        }
        # Non-terminating errors can be checked via
        if ($Error) {
            # Write the $Error to the $Errorlog
            #$Error | Add-Content -Encoding $Encoding $ErrorLog
            #$Error.Clear()
            Write-host $error
        }
        Write-Debug "Exiting $($MyInvocation.MyCommand)"    
} # End Get-Analysis

#Fix formatting of Analysis Reports 
function add-toTopOfFile($logFolder) {
	foreach ($path in Get-ChildItem -path "$AnalysisDir\$LogFolder" -Filter "*.csv" -Recurse -Depth 2) {
		#echo $path.fullname
		$orig = Get-Content $path.fullname
		$new = 'sep=,'
		set-content $path.fullname -value $new, $orig
	}
}


function add-toTopOfAnalysisFile {
    start-sleep -Seconds 1 # wait to be sure the analysis is done writing to the file 
	foreach ($path in Get-ChildItem -path "$AnalysisDir\Analysis_$Runtime" -Filter "*.csv" -Recurse -Depth 2) {
		#echo $path.fullname
		$orig = Get-Content $path.fullname
		$new = 'sep=,'
		set-content $path.fullname -value $new, $orig
	}
}

function remove-fromTopOfFile($logFolder) { #Remove Sep=,
    foreach ($path in Get-ChildItem -path "$AnalysisDir\$logFolder" -Filter "*.csv" -Recurse -Depth 2) {
        #echo $path.fullname
        $orig = Get-Content $path.fullname
        #$new = $orig.Replace('sep=,','')
        $new = $orig |Select-Object -Skip 1
        set-content $path.fullname -value $new
    }
}


function startAnalysis($logs) {
    #Logs/Folder to Analyze - Must match folder's name in LogCollector\{folderName} 
    Write-host "Analyzing: $logs"        

    # Remove Any Zero/Almost Zero byte files as they mess up analysis 
    Write-Host " - Removing Blank Files."
    Get-ChildItem -Path "$psscriptroot\LogCollector\$logs\" -Filter "*.csv" -Recurse | ?{$_.PSIsContainer -eq $false -and $_.length -lt 300} | ?{Remove-Item $_.fullname}

    #Remove 'Sep=,' from logs - this is a directive to tell Excell to treat the seperator as a ',' 
    Write-Host " - Formatting Files for Anlysis"
    remove-fromTopOfFile $logs #Remove Sep=,

    #Copy the Analysis Config to .\Analysis\Analysis.conf
    Write-Host " - Setting up Anlysis Scripts"
    Copy-item -path "$psscriptroot\Toolbox\ReportingConfigs\$logs.conf" -destination "$psscriptroot\Analysis\Analysis.conf" -force
    Start-sleep -seconds 2 
    
    #Run Analysis
    Write-Host " - Running Analysis"
    Get-Analysis $AnalysisDir $psscriptroot
    
    # Add the 'Sep=,' to the top of the analysis file 
    Write-Host " - Formatting Anlysis Files for Excel"
    add-toTopOfAnalysisFile

    # Add the 'Sep=,' value back to the top of each log for ease of use with Excel 
    Write-Host " - Re-Formatting Files for Excel"
    add-toTopOfFile $logs

    #Signal Completion 
    Write-host "Completed."
}


#### Catch Switches with Ifs ####
#################################

#AutoRuns
If($Autorunsc){
    #Logs/Folder to Analyze - Must match folder's name in LogCollector\{folderName} 
    $logFolderName = "Autorunsc" 
    startAnalysis $logFolderName  
    
}

#ChromeExtensionListing 
If($ChromeExtensionListing){       
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "ChromeExtensionListing"
    startAnalysis $logFolderName
}

#FireFoxExtensionListing 
If($FireFoxExtensionListing){
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "FireFoxExtensionListing"
    startAnalysis $logFolderName

}

#LocalAdmins
If($LocalAdmins){
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "LocalAdmins"    
    startAnalysis $logFolderName
    
}

#SchedTasks 
If($SchedTasks){
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "SchedTasks"
    startAnalysis $logFolderName
    
}

#SysmonNetwork10080
If($SysmonNetwork10080){
    #Logs/Folder to Analyze in LogCollector\* 
    $logFolderName = "SysmonNetwork10080"
    startAnalysis $logFolderName
    
}

#SysmonProcess10080
If($SysmonProcess10080){
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "SysmonProcess10080"
    startAnalysis $logFolderName
    
}

#
If($AuditClearTextPasswordsTextCUsers){
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "Audit-ClearTextPasswordsTextCUsers"
    startAnalysis $logFolderName    
}

#
If($AuditClearTextPasswordsDocXls){
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "Audit-ClearTextPasswordsDocXlsCUsers"
    startAnalysis $logFolderName    
}

########## Untested #############
#################################

#BrowserExtensions 
If($BrowserAddonsView){
    #Logs/Folder to Analyze in LogCollector\*
    $logFolderName = "BrowserAddonsView"
    startAnalysis $logFolderName
}



