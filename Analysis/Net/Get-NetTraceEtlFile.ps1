<#
.SYNOPSIS
Get-NetTraceEtlFile.ps1

This Script Will Analyze the csv files in Kansa_NG*\NetTracePacketCapture* (prior to being moved to results) for uniq PSComputerNames. 
Then it will pull back all of the Etl files & convert them to Cap files for use in Wireshark, etc. 

Simsay, Jason: Modified for LogParser output to CSV.
.NOTES
DATADIR NetTracePacketCapture*
#>

# ~\Kansa_NG_2.3.2.1\Output_20200515105328\NetTracePacketCapture*
$NetTracePacketCapture_FolderLocation = Get-Location

#Change Colors of Powershell's Download Status Bar 
$Host.PrivateData.ProgressBackgroundColor='Black'
$Host.PrivateData.ProgressForegroundColor='Green'

#Array to hold ComputerNames
$computerNameArray = @() 

#Get list of all CSV files in the directory 
$Files = Get-ChildItem -Path $NetTracePacketCapture_FolderLocation | Where-Object Name -like "*.csv"
#For each CSV File in the directory, get the computer name 
foreach ($File in $Files){   
  # Import the CSV File and assign it to the variable $CSV
    $CSV = Import-Csv -Path $File.Fullname
    # Get the PSComputerNames listed in the csv
    $computerName = $CSV.PSComputerName | Sort-Object -Unique
    $computerNameArray += $computerName
    
}

#Get the ETL files that were created by the packet capture module 
foreach ($computer in $computerNameArray) {
  # Create New PSRemoting Session 
  Write-Verbose "Downloading Etl capture file from: $computer"
  $pssession = New-PSSession -ComputerName $computer
  #Copy the file from the PSRemoting Session 
  Copy-Item "C:\ProgramData\nettrace\*.etl" "$NetTracePacketCapture_FolderLocation\$computer-nettrace.etl" -FromSession $pssession
  Start-Sleep -Seconds 1 # Small pause before deleting file to ensure the file is not in use. 
  Invoke-Command -Session $pssession -Command {Remove-Item "C:\ProgramData\nettrace\*" -Recurse -Force }
  # Tear down the PSSession 
  $pssession | Remove-PSSession

}

#Import Module 
import-module PEF
#Wait 2 Seconds 
Start-Sleep -Seconds 2

#Convert Etl files to Cap files using MessageAnalyzer 
$EtlFiles = Get-ChildItem -Path $NetTracePacketCapture_FolderLocation | Where-Object Name -like "*.etl"
#For each CSV File in the directory, get the computer name 
foreach ($File in $EtlFiles){   
  #File name only 
  $fileFullName = $File.FullName 
  $fileName = $File.BaseName
  $capFilePath =  "$NetTracePacketCapture_FolderLocation\$FileName.cap"
  #Conver the Etl file to a Cap file 
  $s = New-PefTraceSession -Path "$capFilePath" -SaveOnStop; $s | Add-PefMessageProvider -Provider "$fileFullName"; $s | Start-PefTraceSession
    
}
