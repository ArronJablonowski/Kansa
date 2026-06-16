<#
.SYNOPSIS
    Get-SysmonNetwork.ps1 extracts all Sysmon Network Events [Evt 3] from the Sysymon Operational Event log for a specified timeframe
.DESCRIPTION
    Query the event log and pull back all Sysmon Process Creation events. Configured for *** Sysmon v8.04 ***
    Event 3
    Query and filter
.PARAMETER
    Switch to pull back Network events back a desired number of minutes
    [int32]$BackMins=180. Defaults to 180 minutes = 3 hours
    Some time guides: 180 = 3 hours, 360 = 6hours, 720 = 12 hours, 1440 = 1 day, 2880 = 2 days, 4320 = 3 days, 10080 = 7 days
    Keep in mind depending on sysmon configuration, the longer the timeframe the more work to pull events.
.EXAMPLE
    .\Get-SysmonNetwork.ps1 -BackMins 180
    .\Get-SysmonNetwork.ps1 180
    .\Get-SysmonNetwork.ps1

    UtcTime             : 2019-03-28 18:17:10.894
    HostName            : PCName.Domain.local
    Version             : 5
    EventType           : Network connection detected
    EventID             : 3
    RuleName            :
    ProcessGuid         : cd1e45d5-ec62-5c9c-0000-0010eed8c5a1
    ProcessId           : 17616
    Image               : C:\Users\Arron_PC\AppData\Roaming\Zoom\bin\Zoom.exe
    User                : {domain}\Arron_PC
    Protocol            : udp
    Initiated           : False
    SourceIsIpv6        : False
    SourceIp            : 192.168.45.60
    SourceHostname      : PCName.Domain.local
    SourcePort          : 51188
    SourcePortName      :
    DestinationIsIpv6   : False
    DestinationIp       : 8.5.129.156
    DestinationHostname : zoomdvm156mmr.zoom.us
    DestinationPort     : 8801
    DestinationPortName : http

.LINK
    https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon

.NOTES
    Configured for Sysmon v8.04
    Sysmon configuration plays a large part in the amount of events.
    For offline parsing of event logs modify script to remove "-LogName" and add "-Path <PATH_to_Logs>". 
    e.g RawEvents = Get-WinEvent -Path c:\case\sysmon.evtx | Where-Object {$_.TimeCreated -ge $BackTime} | Where-Object { $_.Id -eq 3}
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
$RawEvents = Get-KansaWinEvents -FilterHashtable @{LogName="Microsoft-Windows-Sysmon/Operational"; Id=3; StartTime=$BackTime} -MissingMessage "No Sysmon network connection events (event ID 3) were found in the last $BackMins minutes."
$RawEvents | ForEach-Object {  
    if ($_.Properties.Count -lt 18) {
        Write-Warning "Sysmon network event at $($_.TimeCreated) is missing expected event data fields. Skipping extended processing for this event."
        return
    }

    $PropertyBag = @{
        HostName = $_.MachineName
        Version=$_.Version
        EventType = $_.Message.Split(":")[0]
        EventID = $_.Id
        RuleName = $_.Properties[0].Value
        UtcTime = $_.Properties[1].Value   
        ProcessGuid = $_.Properties[2].Value
        ProcessId = $_.Properties[3].Value
        Image = $_.Properties[4].Value
        User = $_.Properties[5].Value
        Protocol = $_.Properties[6].Value
        Initiated = $_.Properties[7].Value
        SourceIsIpv6 = $_.Properties[8].Value
        SourceIp = $_.Properties[9].Value
        SourceHostname = $_.Properties[10].Value
        SourcePort = $_.Properties[11].Value
        SourcePortName = $_.Properties[12].Value
        DestinationIsIpv6 = $_.Properties[13].Value
        DestinationIp = $_.Properties[14].Value
        DestinationHostname = $_.Properties[15].Value
        DestinationPort = $_.Properties[16].Value
        DestinationPortName = $_.Properties[17].Value
    }
    $Output = New-Object -TypeName PSCustomObject -Property $PropertyBag
    # When modifying PropertyBag remember to change Seldect-Object for ordering below
    $Output | Select-Object UtcTime, HostName, Version, EventType, EventID, RuleName, ProcessGuid, ProcessId, Image, User, Protocol, Initiated, SourceIsIpv6, SourceIp, SourceHostname, SourcePort, SourcePortName, DestinationIsIpv6, DestinationIp, DestinationHostname, DestinationPort, DestinationPortName
}        
