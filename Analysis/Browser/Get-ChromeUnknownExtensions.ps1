<#
.SYNOPSIS
Get-NetTraceEtlFile.ps1

This Script Will Analyze the csv files in Kansa_NG*\NetTracePacketCapture* (prior to being moved to results) for uniq PSComputerNames. 
Then it will pull back all of the Etl files & convert them to Cap files for use in Wireshark, etc. 

Simsay, Jason: Modified for LogParser output to CSV.
.NOTES
DATADIR ChromeExtensionListing
#>

#Change Colors of Powershell's Download Status Bar 
$Host.PrivateData.ProgressBackgroundColor='Black'
$Host.PrivateData.ProgressForegroundColor='Green'

# ~\Kansa_NG_2.3.2.1\Output_20200515105328\NetTracePacketCapture*
$chromeExtensionsListingLocation = Get-Location
New-Item -Path "$chromeExtensionsListingLocation" -Name "Loot" -ItemType "directory" #Make Loot folder 

#Get list of all CSV files in the directory 
$Files = Get-ChildItem -Path $chromeExtensionsListingLocation | Where-Object Name -like "*.csv"
#For each CSV File in the directory, get the computer name 
foreach ($File in $Files){   
  # Import the CSV File and assign it to the variable $CSV
    $CSV = Import-Csv -Path $File.Fullname
    #For each line in CSV get the column name value   
    foreach ($line in $CSV){
            #Name	Extension	WindowsUser	PSComputerName
            $extName = $line.Name 
            $extCode = $line.Extension 
            $winUser = $line.WindowsUser 
            $CompName = $line.PSComputerName
            $extArray = @() #Array to hold Extension Codes of previously downloaded Extensions 
            #IF extName contains Unknown           
            IF(($extName -match "Unknown") -and ($extCode -notlike "Temp") -and (!($extCode -in $extArray))) {
                # New-Item -Path "$chromeExtensionsListingLocation\Loot" -Name "$extCode" -ItemType "directory" #Make Loot folder 
                Write-Verbose "Downloading Extension: $extCode - $CompName"
                $extArray += $extCode #Add the extension code to the extension array so you dont double up on the same extension. 
                                
                # Create New PSRemoting Session
                $pssession = New-PSSession -ComputerName $CompName
                
                #Copy the file from the PSRemoting Session 
                Copy-Item "C:\Users\$winUser\AppData\Local\Google\Chrome\User Data\Default\Extensions\$extCode" "$chromeExtensionsListingLocation\Loot\" -FromSession $pssession -Recurse 
                
                # Invoke-Command -Session $pssession -Command {Remove-Item "C:\ProgramData\nettrace\*" -Recurse -Force }
                
                # Tear down the PSSession 
                $pssession | Remove-PSSession
            }
    }    
}