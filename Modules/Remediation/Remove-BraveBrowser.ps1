<#
.SYNOPSIS
Remove-BraveBrowser.ps1 
    This script will REMOVE Brave Browser 
.NOTES

#>

#Stop-Process -name brave -Force 
#Stop-Process -name brave.exe -Force 
#Stop-Process -name bravebrowser -Force 
#Start-Sleep -Seconds 1
#Make an array to hold the extension objects 
$listOfExtensions = @()

# Get the Chrome Extension folder listing for each user 
$users = Get-ChildItem C:\Users
foreach ($user in $users){
    $folder = $($user.FullName)+"\AppData\Local\BraveSoftware\"
    #Write-Host "checking"
    If(Test-Path $folder){
        #$found = "yes"
        #$BraveBrowserFiles = Get-ChildItem $folder -Recurse
        #Will Need to Remove Braver Here 
        Remove-Item $folder -Force -Recurse
        #make a new PS object for each extension and assign the object's properties  
        $hostName = $env:COMPUTERNAME 
        $extObj = new-object PSObject -property @{Host=$hostName;BraveLocation=$folder;WindowsUser=$user}
        $listOfExtensions += $extObj
    
    }
}

#$listOfExtensions | Where-Object {$_.Name -ne $Null} | select-object -Property Host, BraveLocation, WindowsUser
$listOfExtensions | select-object -Property Host, BraveLocation, WindowsUser