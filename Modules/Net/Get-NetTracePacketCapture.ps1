<#
.SYNOPSIS
Get-NetTracePacketCapture.ps1
   
This module will allow you to run packet captures on remote hosts using a native (ie. without installing anything) Windows tool, netsh. 

!! This module can be very SLOW !!
 - this will run longer than the amount of time specified due to netsh compiling the network capture.
 - if connection to remote host is lost while this module is running, the trace will continue to run on the host until the size limit is reached and it will persist through host reboots.
 - time guide (300s=5m, 600s=10m, 1200s=20m, 1800s=30m, 2400s=40m, 2700=45m, 3600s=60m, 7200s=2h) 

.NOTES
 Resources for netsh trace commands and switches:
 - netsh trace show capturefilterhelp  -- ** Get list of filters 
 - https://www.concurrency.com/blog/december-2017/netsh-packet-captures
 - https://isc.sans.edu/diary/No+Wireshark%3F+No+TCPDump%3F+No+Problem%21/19409
 - https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd878517(v=ws.10)
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [int32]$NumSeconds=600
)
#Stop any captures that may be running and blocking our packet capture attempt 
netsh trace stop 
Start-Sleep -Seconds 5

#File Paths
$packetCaptureFile = "C:\ProgramData\nettrace\$env:COMPUTERNAME-nettrace.etl"
$packetCabFile = "C:\ProgramData\nettrace\$env:COMPUTERNAME-nettrace.cab"
#FolderPath 
$folderToHoldCaptute = "C:\ProgramData\nettrace"

#Delete if exists 
If (Test-Path $packetCaptureFile){
    rm $packetCaptureFile
}
If (Test-Path $packetCabFile){
    rm $packetCabFile
}

#make folder to store nettrace files 
New-Item -ItemType Directory -Force -Path $folderToHoldCaptute #Make a new folder to store (& kind of hide) the etl capture file - ProgramData is a hidden folder in the root of C:\

#Start capture with netsh - capture WILL STOP when sleep time has been reached or file size exceeds 512MB, whichever comes first
netsh trace start persistent=yes maxsize=512 filemode=single capture=yes Ethernet.Type="(IPv4,IPv6)" tracefile=$packetCaptureFile

#Example of an IP specific filtered net trace
    # netsh trace start persistent=yes maxsize=512 capture=yes Ethernet.Type=IPv4 IPv4.Address=157.59.136.1 tracefile=C:\path\file.etl

#sleep to control length of capture 
Start-Sleep -Seconds $NumSeconds

#Stop the capture 
netsh trace stop 