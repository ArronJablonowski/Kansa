<#
    This script Dumps a sorted list of hosts from AD, then checks if WinRM is available for a connection. 
    It will continue to recuresevly search the network until all live hosts are exhausted. 
#>

#Controls the Number of Live Hosts per file
$LiveHostMaxCount = 100

############################################
rm LiveHosts_*.txt
rm DeadHosts.txt
rm ADDump.txt
Start-sleep -seconds 2
#Var to hold name of host list 
$ADDump = "./ADDump.txt"
#Dump sorted list of computers from AD
Get-ADComputer -Filter 'ObjectClass -eq "Computer"' | Select -Expand DNSHostName | sort -casesensitive -unique | tee-Object $ADDump
# $userinput=$args[0]
#$userinput = ".\Test4.txt" 
$testConnectionSuccess = 0
$testConnectionFail = 0 
$testedTotal = 0 
$liveHostCounter = 0
$hostFileCounter = 1  
$aliveHosts = ".\LiveHosts_$hostFileCounter.txt"
$deadHosts = ".\DeadHosts.txt"
rm "DeadHosts*.txt"

#Check AD Dump  
while((Test-Path $ADDump -ErrorAction SilentlyContinue)){  

    cls 
    Write-Host " "
    Write-Host "Testing WinRM Connections."
    Write-Host "************************** "

    foreach($line in Get-Content $ADDump) { # read file line by line
        If (!([string]::IsNullOrEmpty($line))){
            $testResults = $null
            $testResults = Test-WSMan -ComputerName $line -Authentication default -ErrorAction SilentlyContinue
            if($testResults -ne $null){ 
                Write-Host " - Able to connect to: $line"
                $liveHostCounter = $liveHostCounter +1 
                If($liveHostCounter -gt $liveHostMaxCount ){
                $hostFileCounter = $hostFileCounter + 1
                    $aliveHosts = ".\LiveHosts_$hostFileCounter.txt"
                    #resetCounter
                    $liveHostCounter = 1
                }
                Add-Content -Path $aliveHosts -Value $line
                # $liveHostCounter = $liveHostCounter +1 

                $testConnectionSuccess = $testConnectionSuccess + 1
            }Else{ # treat the line as a domain
                Write-Host " - Unable to connect to: $line"
                $testConnectionFail = $testConnectionFail + 1
                Add-Content -Path $deadHosts -Value $line
                
            }
            $testedTotal = $testedTotal + 1
        }
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
    Start-Sleep -Seconds 10
    rm $ADDump
    $content = Get-Content $deadHosts
    if ($null -ne $content) {
        Copy-Item $deadHosts $ADDump  
        Start-sleep -seconds 2
        rm $deadHosts
        Start-sleep -seconds 2
    } 

}