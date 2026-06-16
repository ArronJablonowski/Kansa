<#
    This script is attempting to detect live hosts with WinRM enabled. 
    This will hopefully reduce the time to check via enter-pssession...  

#>
$input=$args[0]

# Controls the Number of Live Hosts per file
$LiveHostMaxCount = 250
############################################

#$input = ".\Test4.txt" 
$testConnectionSuccess = 0
$testConnectionFail = 0 
$testedTotal = 0 
$liveHostCounter = 0
$hostFileCounter = 1  
$aliveHosts = ".\LiveHosts_$hostFileCounter.txt"
$deadHosts = ".\DeadHosts.txt"

cls 
Write-Host " "
Write-Host "Testing WinRM Connections."
Write-Host "************************** "

If($input -ne $null){
    foreach($line in Get-Content $input) { # read file line by line
        $testResults = $null
        $testResults = Test-WSMan -ComputerName $line -Authentication default -ErrorAction SilentlyContinue
        if($testResults -ne $null){ # line is IPv4 address 
            Write-Host " - Able to connect to: $line"
            $liveHostCounter = $liveHostCounter +1 
            If($liveHostCounter -gt $liveHostMaxCount ){
                $hostFileCounter = $hostFileCounter + 1
                $aliveHosts = ".\LiveHosts_$hostFileCounter.txt"
                #resetCounter
                $liveHostCounter = 1
            }
            Add-Content -Path $aliveHosts -Value $line
            $testConnectionSuccess = $testConnectionSuccess + 1
        }Else{ # treat the line as a domain
           Write-Host " - Unable to connect to: $line"
           $testConnectionFail = $testConnectionFail + 1
           Add-Content -Path $deadHosts -Value $line
        }
        $testedTotal = $testedTotal + 1
    }
}Else {
    Write-Host "Error! Please provide a file path to a list of hosts to check."
}

Write-Host " "
Write-Host " "
Write-Host "WinRM Connection Stats"
Write-Host "----------------------"
Write-Host " Total Hosts: $testedTotal"
Write-Host " Alive Hosts: $testConnectionSuccess "
Write-Host "  Dead Hosts: $testConnectionFail    "
Write-Host " "
Write-Host " "