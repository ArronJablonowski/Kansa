<#
.SYNOPSIS
Get-NetTraceEtlFile.ps1

This Script Will Analyze the csv files in Kansa_NG*\NetTracePacketCapture* (prior to being moved to results) for uniq PSComputerNames. 
Then it will pull back all of the Etl files & convert them to Cap files for use in Wireshark, etc. 

Simsay, Jason: Modified for LogParser output to CSV.
.NOTES
DATADIR MemoryWinPmem
#>

# ~\Kansa_NG_2.3.2.1\Output_20200515105328\MemoryWinPmem
$MemoryWinPmem_FolderLocation = Get-Location

#Change Colors of Powershell's Download Status Bar 
$Host.PrivateData.ProgressBackgroundColor='Black'
$Host.PrivateData.ProgressForegroundColor='Green'

#Array to hold ComputerNames
$computerNameArray = @() 

#Get list of all CSV files in the directory 
$Files = Get-ChildItem -Path $MemoryWinPmem_FolderLocation | Where-Object Name -like "*.csv"
#For each CSV File in the directory, get the computer name 
foreach ($File in $Files){   
  # Import the CSV File and assign it to the variable $CSV
    $CSV = Import-Csv -Path $File.Fullname
    # Get the PSComputerNames listed in the csv
    $computerName = $CSV.PSComputerName | Sort-Object -Unique
    $computerNameArray += $computerName
    
}

# Make sure the computer Array does not hold more that 1 host name - Don't want to accidentially fill/kill a HDD/OS. 
If($computerNameArray.Count -lt 2){
  #Get the MemDump files that were created by the mem dump module 
  foreach ($computer in $computerNameArray) {
    # Create New PSRemoting Session 
    $pssession = New-PSSession -ComputerName $computer
    #Copy the file from the PSRemoting Session 
    Copy-Item "C:\ProgramData\winpmem\*MemCap.aff4" "$MemoryWinPmem_FolderLocation\$computer-MemCap.aff4" -FromSession $pssession
    Copy-Item "C:\ProgramData\winpmem\*aff4-md5.txt" "$MemoryWinPmem_FolderLocation\$computer-aff4-md5.txt" -FromSession $pssession
    Copy-Item "C:\ProgramData\winpmem\*aff4-sha256.txt" "$MemoryWinPmem_FolderLocation\$computer-aff4-sha256.txt" -FromSession $pssession
    Copy-Item "C:\ProgramData\winpmem\*aff4-sha512.txt" "$MemoryWinPmem_FolderLocation\$computer-aff4-sha512.txt" -FromSession $pssession
    Start-Sleep -Seconds 1 # Small pause before deleting file to ensure the file is not in use. 
    Invoke-Command -Session $pssession -Command {Remove-Item "C:\ProgramData\winpmem\*" -Recurse -Force }
    # Tear down the PSSession 
    $pssession | Remove-PSSession

  }
}
else {
  exit
}
