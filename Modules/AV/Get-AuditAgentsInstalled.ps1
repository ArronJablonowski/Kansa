<#
.SYNOPSIS
AV-AuditTrendAVInstalled.ps1 
    
.NOTES

#>

#Make an array to hold the extension objects 
$listOfExtensions = @()
$HostName = $env:COMPUTERNAME

#Check if Exists
$resultTrend = "null"   # trend 
$resultBMC = "null"     # BMC 
$resultNessus = "null"  # Nessus 

# Location of EXE 
$trendAgent = "C:\Program Files (x86)\Trend Micro\OfficeScan Client\PccNTMon.exe" #Trend Micro OfficeScan Antivirus real-time scan monitor
$bmcAgent = "C:\Program Files\BMC Software\Client Management\Client\bin\mtxagent.exe"
$nessusAgent = "C:\Program Files\Tenable\Nessus Agent\nessusd.exe"

#IF Trend Exists 
If (Test-Path $trendAgent) {         
    $resultTrend = "Found"
}
else {
    $resultTrend = "MISSING"
}

#IF BMC Exists 
If (Test-Path $bmcAgent) {         
    $resultBMC = "Found"
}
else {
    $resultBMC = "MISSING"
}

#IF Nessus Exists  
If (Test-Path $nessusAgent) {         
    $resultNessus = "Found"
}
else {
    $resultNessus = "MISSING"
}

$obj = new-object PSObject -property @{HostName=$HostName;TrendAV=$resultTrend;NessusAgent=$resultNessus;BMCAgent=$resultBMC}
#Add to 
#$listOfExtensions += $obj
$obj| select-object -Property HostName, TrendAV, NessusAgent, BMCAgent
#$listOfExtensions | Where-Object {$_.Name -ne $Null} | select-object -Property HostName, TrendAV, NessusAgent, BMCAgent