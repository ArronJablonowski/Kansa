<#
.SYNOPSIS
    Get-SysmonProcess.ps1 extracts all Sysmon Process Create Events [Evt 1] from the Sysymon Operational Event log for a specified timeframe
.DESCRIPTION
    Query the event log and pull back all Sysmon Process Creation events. Configured for *** Sysmon v8.04 ***
    Event 1
    Query and filter
.PARAMETER
    Switch to historically pull back Process Creation for a desired number of minutes 
    [int32]$BackMins=180. Defaults to 180 minutes (3 hours) 
    *** Keep in mind depending on sysmon configuration, the longer the timeframe the more work to pull events ***
    Some time guides: 180 = 3 hours, 360 = 6hours, 540 = 9 hours 720 = 12 hours, 1440 = 1 day, 2880 = 2 days, 4320 = 3 days, 10080 = 7 days

.EXAMPLE
    .\Get-SysmonProcess.ps1 -BackMins 720
    .\Get-SysmonProcess.ps1 720
    .\Get-SysmonProcess.ps1

    DateUTC           : 2019-03-29 20:36:40.584
    HostName          : PCName.Domain.local
    Company           : Microsoft Corporation
    Product           : Microsoft� Windows� Operating System
    WinVersion        : 10.0.xxxxx.xx (WinBuild.xxxxx.xxxx)
    Description       : Application Frame Host
    EventID           : 1
    EventType         : Process Create
    ProcessGuid       : cd1e45d5-81d8-5c9e-0000-0010c3777db7
    ProcessId         : 8900
    Image             : C:\Windows\System32\ApplicationFrameHost.exe
    CommandLine       : C:\WINDOWS\system32\ApplicationFrameHost.exe -Embedding
    MD5               : 5D619E710E18E821510E9507C6E553B7
    SHA256            : 2387773C19595F9E71A371A6FA393CE225DBF11628CFE698300F5E92D584B3F5
    CurrentDirectory  : C:\WINDOWS\system32\
    User              : Domain\username
    LogonGuid         : cd1e45d5-7ca6-5c9e-0000-0020ac6705b7
    LogonId           : 3070584748
    TerminalSessionId : 12
    IntegrityLevel    : Medium
    ParentProcessGuid : cd1e45d5-2e83-5c90-0000-001064bf0100
    ParentProcessId   : 1032
    ParentImage       : C:\Windows\System32\svchost.exe
    ParentCommandLine : C:\WINDOWS\system32\svchost.exe -k DcomLaunch -p

.LINK
.NOTES
Configured for Sysmon v8.04
Sysmon configuration plays a large part in the amount of events.
I have configured the module to report back for a Sysmon hash configuration of: MD5,SHA1,SHA256. 
For any other configurations you will need to reconfigure the Propertybag array to report relevant algorythms.
For simplicity I have also included a hashes field commented out. If included, it will show all calculated hashes in one line.
When modifying $PropertyBag, remember to change the final Select-Object to ensure correct feilds are selected in order.
For offline parsing of event logs modify script to remove "-LogName" and add "-Path <PATH_to_Logs>". 
e.g RawEvents = Get-WinEvent -Path c:\case\sysmon.evtx | Where-Object {$_.TimeCreated -ge $BackTime} | Where-Object { $_.Id -eq 1}
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [int32]$BackMins=180
)

function Get-KansaWinEvents {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$FilterHashtable,
        [Parameter(Mandatory=$true)]
        [string]$MissingMessage
    )

    try {
        Get-WinEvent -FilterHashtable $FilterHashtable -ErrorAction Stop
    }
    catch [System.Diagnostics.Eventing.Reader.EventLogNotFoundException] {
        $Error.Clear()
        Write-Warning "Event log '$($FilterHashtable.LogName)' was not found on this host. $MissingMessage"
        @()
    }
    catch {
        $Error.Clear()
        if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') {
            Write-Warning $MissingMessage
            @()
        }
        elseif ($_.Exception.Message -like '*There is not an event log*') {
            Write-Warning "Event log '$($FilterHashtable.LogName)' was not found on this host. $MissingMessage"
            @()
        }
        else {
            Write-Warning "Unable to query event log '$($FilterHashtable.LogName)': $($_.Exception.Message)"
            @()
        }
    }
}

$BackTime=(Get-Date) - (New-TimeSpan -Minutes $BackMins)
$RawEvents = Get-KansaWinEvents -FilterHashtable @{LogName="Microsoft-Windows-Sysmon/Operational"; Id=1; StartTime=$BackTime} -MissingMessage "No Sysmon process creation events (event ID 1) were found in the last $BackMins minutes."
#Write-Host $RawEvents
#Exit
$RawEvents | ForEach-Object {  
    if ($_.Properties.Count -lt 21) {
        Write-Warning "Sysmon process event at $($_.TimeCreated) is missing expected event data fields. Skipping extended processing for this event."
        return
    }

    $Hashes = @{}
    $_.Properties[16].Value -split "," | ForEach-Object {
        $HashParts = $_ -split "=", 2
        if ($HashParts.Count -eq 2) {
            $Hashes[$HashParts[0]] = $HashParts[1]
        }
    }

    if (-not $Hashes.ContainsKey('MD5')) {
        Write-Warning "Sysmon process event at $($_.TimeCreated) does not include an MD5 hash field."
    }

    if (-not $Hashes.ContainsKey('SHA256')) {
        Write-Warning "Sysmon process event at $($_.TimeCreated) does not include a SHA256 hash field."
    }

    $PropertyBag = @{
        HostName = $_.MachineName
        Version=$_.Version
        EventType = $_.Message.Split(":")[0]
        EventID = $_.Id
        DateUTC = $_.Properties[1].Value
        ProcessGuid = $_.Properties[2].Value
        ProcessId = $_.Properties[3].Value
        Image = $_.Properties[4].Value
        WinVersion = $_.Properties[5].Value
        Description = $_.Properties[6].Value
        Product = $_.Properties[7].Value
        Company = $_.Properties[8].Value
        CommandLine = $_.Properties[9].Value
        CurrentDirectory = $_.Properties[10].Value  # ??
        User = $_.Properties[11].Value
        LogonGuid = $_.Properties[12].Value
        LogonId = $_.Properties[13].Value
        TerminalSessionId = $_.Properties[14].Value
        IntegrityLevel = $_.Properties[15].Value
        #Hashes = ($_.Properties[16].Value.Split(",")) # shows hash feild with all configured hash types one field
        MD5 = $Hashes['MD5'] # requires logging of MD5
        SHA256 = $Hashes['SHA256'] # required logging of SHA256
        ParentProcessGuid = $_.Properties[17].Value
        ParentProcessId = $_.Properties[18].Value
        ParentImage = $_.Properties[19].Value
        ParentCommandLine = $_.Properties[20].Value
    }
    $Output = New-Object -TypeName PSCustomObject -Property $PropertyBag
    
    #$Output | Group-Object -Property CommandLine | sort count | select count,name
    $Output | Select-Object DateUTC, HostName, Company, Product,  WinVersion, Description, EventID, EventType, ProcessGuid, ProcessId, Image, CommandLine, MD5, SHA256, CurrentDirectory, User, LogonGuid, LogonId, TerminalSessionId, IntegrityLevel, ParentProcessGuid, ParentProcessId, ParentImage, ParentCommandLine
    
} 
