<#
.SYNOPSIS
Get-NetTracePacketCapture_Persistent_STOP.ps1
   
This module will stop a netsh trace session 

 - The trace will run on the host until the size limit is reached or nettrace is stopped, and it can persist through host reboots. 

.NOTES
 Resources for netsh trace commands and switches:
 - netsh trace show capturefilterhelp  -- ** Get list of filters 
 - https://www.concurrency.com/blog/december-2017/netsh-packet-captures
 - https://isc.sans.edu/diary/No+Wireshark%3F+No+TCPDump%3F+No+Problem%21/19409
 - https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd878517(v=ws.10)
#>

#Stop any captures that may be running 
netsh trace stop
