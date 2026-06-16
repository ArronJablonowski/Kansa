<#
.SYNOPSIS
Get-MemoryWinPmem.ps1
   
This module will allow you to dump the live memory on systems you may have 
identified as needing more analysis. You can use the dump in other tools, 
such as Rekall, Redline, or Volitility.

!! The dump is quickish; however, transferring it accross the network can be slow !!

After the memory dump has completed, its then hashed via md5, sha256, and sha512 for use in forensic cases.  

.NOTES
OUTPUT bin
Next line is required by Kansa for proper handling of third-party binary.
The BINDEP directive below tells Kansa where to find the third-party code.
BINDEP .\Modules\bin\winpmem-2.1.post4.exe
OUTPUT bin
#>

#Memory Dump location goes here:  
# -- ex: $memDumpLocation = "C:\<path>\$env:COMPUTERNAME-MemCap.aff4" --  
New-Item -ItemType Directory -Force -Path C:\ProgramData\winpmem #Make a new folder to store (& kind of hide) the dump and hash files on the system - ProgramData is a hidden folder in the root of C:\
$memDumpLocation = "C:\ProgramData\winpmem\$env:COMPUTERNAME-MemCap.aff4"

#Get C:\ freespace in GB 
$CDriveSpecs = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID='C:'" | Select-Object -Property DeviceID, DriveType, VolumeName, @{L='FreeSpaceGB';E={"{0:N2}" -f ($_.FreeSpace /1GB)}}, @{L="Capacity";E={"{0:N2}" -f ($_.Size/1GB)}} | Select-Object -Property Capacity, FreeSpaceGB
$freeSpaceGB_CDrive = $CDriveSpecs.FreeSpaceGB

#Get amount of RAM on System in GB
$systemRAMbytes = Get-WmiObject -class "win32_physicalmemory" -namespace "root\CIMV2"
$systemRAMGB = $systemRAMbytes.Capacity /1Gb 

#Check if there is enough space on the C:\ drive to run a memory dump without filling the drive - **Padded C:\ Drive's free space by another 10G for safety ($freeSpaceGB_CDrive - 10) 
if(($freeSpaceGB_CDrive - 10) -gt $systemRAMGB ){

    #Start Memory Dump via winpmem -- $env:SystemRoot = C:\Windows 
    Start-Process -FilePath $env:SystemRoot\winpmem-2.1.post4.exe -ArgumentList "-o $memDumpLocation" -Wait
    #Hash the Memory dump for forensics use - MD5 
    Get-FileHash -Path "$memDumpLocation" -Algorithm md5 | Format-List | Tee-Object -FilePath "$memDumpLocation-md5.txt"
    #Hash the Memory dump for forensics use - sha256 
    Get-FileHash -Path "$memDumpLocation" -Algorithm sha256 | Format-List | Tee-Object -FilePath "$memDumpLocation-sha256.txt"
    #Hash the Memory dump for forensics use - sha512 
    Get-FileHash -Path "$memDumpLocation" -Algorithm sha512 | Format-List | Tee-Object -FilePath "$memDumpLocation-sha512.txt"

} Else{
    echo "C: Drive is too full to save a memory dump. Please investigate large files on the host." | Tee-Object -FilePath "$memDumpLocation-Error.txt"
}

#optional: add feature to copy image file to a centeral repo for further analysis

