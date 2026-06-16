<#
.SYNOPSIS
Check-VTHash_SYSMON_Procs.ps1
    Virus Total Lookup - Threat Hunt running Processes Hashes on a large scale 

.NOTES
.NOTES
The next line is needed by Kansa.ps1 to determine how to handle output
OUTPUT CSV

DATADIR AnalysisReports
#>

# VirusTotal API Key 
$apikeyVirusTotal = "VT_API_KEY_GOES_HERE"

#Change Colors of Powershell's Download Status Bar 
$Host.PrivateData.ProgressBackgroundColor='Black'
$Host.PrivateData.ProgressForegroundColor='Green'

# Returns .\AnalysisReports\* when executed from Kansa 
$AnalysisFolderLocation = Get-Location

#$counter = 1 #to hold a cound of iterations through the SubmitVirusTotalURL - aka dont waste time by sleeping on the first submission 


# Hashtable - known 
$knownObjects = @{
    "278BEF42487B4B1C253577312006A430481DE0B5FB075A914639DD60A8B55B70" = "C:\IBM\SDP\eclipse.exe"
    "C64285605B05599576776B8A9E0E0574262D93A165214EECD7C81C36C9DECDF4" = "C:\IBM\SDP\eclipse.exe"
    "39964680296241B1A5AD6D25A3CB021B7DA9507DB54B3639F1BE011608A9906D" = "C:\IBM\SDP\eclipse.exe"
    "0E4F3E24CF6542EC2F268A01E307F604CF61BB96B6D8AB7DF1EB9DE6A6EB7BB2" = "C:\IBM\SDP\jdk\jre\bin\javaw.exe"
    "C8BD7358DAAA0F473ABC6C717F715297AF1F0E4CE587C7127648FFFA0FCA8495" = "C:\IBM\SDP\jdk\jre\bin\javaw.exe"
    "58B0EFA1E59D1BF4C7FB2373778F38981618C0ABDBB6B8B4F0021D134C3C22FC" = "C:\IBM\SDP\jdk\jre\bin\javaw.exe"
    "664ADB3CE59CCD3748E773B2EAD324FBD25D734629CFEDC018054D4A796CB3E2" = "C:\Lotus\Notes\nsd.exe"
    "1790D4B94176B26767E6AFA4867A20DBA7FBE44761EC07BC1D4469ADA337136E" = "C:\Lotus\Notes\ntmulti.exe"
    "5E8B032D26C2F35FB5F0F2DABC91D7B9671E2C8E73464E4DCB17A5F0731457F0" = "C:\Lotus\Notes\SUService.exe"
    "FB3A54A3EED99495D2CC407ED767DD69784DFFF7962CB9536C85BEDBE5763290" = "C:\Mochasoft\tn5250.exe"
    "CF45DC3EFB09309F4A2F7275A8D011A0D0CF65B3DD69A867A708A78A1076BBB7" = "C:\My Programs\Notepad++\notepad++.exe"
    "5FDA1D49AD9E08035B3893796191AFF7E1DAB06079E2E50FF1DC13911C33AEE5" = "C:\My Programs\Notepad++\updater\GUP.exe"

}

[System.Collections.ArrayList]$hashArray = @() #Array to hold multiple objects 

# VirusTotal Function - API/URI 
Function SubmitVirusTotalURL($hash, $procImage) {
    #Check if the object is known 
    if ($knownObjects.ContainsKey("$hash")){
        $knownObjectDescription = $knownObjects.get_item("$hash")
        Write-Host " ~ Skipping VirusTotal Lookup for Known Object: $hash"
        #Write-Verbose " Object Hash: $hash"
        #Write-Verbose "Object Found: $knownObjectDescription"

        $obj = [PSCustomObject]@{
            'sha256'   = $hash
            'Detections' = "Known Object"
            'TotalScanners' = "na"
            'VTReport' = $knownObjectDescription 
            'Image' = $procImage 
        }

    }
    else{ #If the object is not in the known hash table, then send it to VT 
        #Send to VT 
        Write-Host "Zzz. Sleeping to avoid rate control."
        Start-Sleep -Seconds 16

        #write-host "Checking VirusTotal: $hash"    
        $response = Invoke-WebRequest -Uri "https://www.virustotal.com/vtapi/v2/file/report?apikey=$apikeyVirusTotal&resource=$hash" | ConvertFrom-Json
        #build a Custom PS Object from the resposne data 
        If ($response.response_code -eq 1) {
            $obj = [PSCustomObject]@{
                'sha256'   = $response.sha256
                'Detections' = $response.positives
                'TotalScanners' = $response.total
                'VTReport' = $response.permalink 
                'Image' = $procImage
            }
        }elseif ($response.response_code -eq 0) {
            $obj = [PSCustomObject]@{
                'sha256'   = $hash
                'Detections' = "Unknown Object"
                'TotalScanners' = "na"
                'VTReport' = $response.verbose_msg 
                'Image' = $procImage
            }
        }else{
            $obj = [PSCustomObject]@{
                'sha256'   = $hash
                'Detections' = "Failed to get a response from VirusTotal."
                'TotalScanners' = "Failed to get a response from VirusTotal."
                'VTReport' = "Failed to get a response from VirusTotal."
                'Image' = $procImage
            }
        }    
    }
    #Return the object
    Return $obj 
}

# Import the CSV File and assign it to the variable $CSV
$CSV = Import-Csv -Path "$AnalysisFolderLocation\SysmonProcHashStack.csv"
#For each line in CSV get the column name value   
foreach ($line in $CSV){
    #$hashCount = $line.ct 
    $hash = $line.sha256
    $Img = $line.Image
    #IF($hashCount -lt 10 -and (!([string]::IsNullOrEmpty($hash)))){
    IF(!([string]::IsNullOrEmpty($hash))){
        #Submit the Hash and get the returned object 
        $fileObj = SubmitVirusTotalURL $hash $Img      
        #add the object to the array 
        $hashArray += $fileObj
    }
}

$hashArray | Select-Object Detections,TotalScanners,sha256,Image,VTReport | Export-Csv -Path "$AnalysisFolderLocation\VirusTotalReport.csv";

Start-Sleep -Seconds 2 