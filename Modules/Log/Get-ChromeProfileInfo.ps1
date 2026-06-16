#Make an array to hold the extension objects 
$chromePreferences = @()
# Get the Chrome Extension folder listing for each user 
$users = Get-ChildItem C:\Users
foreach ($user in $users){
    $folder = $($user.FullName)+"\AppData\Local\Google\Chrome\User Data\Default"
    If(Test-Path $folder){
        $prefFile = "$folder\Preferences"
        If(Test-Path $prefFile) {
            $jsonFile = Get-Content -Raw -Path $prefFile | Convertfrom-json
            #$gaia_cookie = ($jsonFile.gaia_cookie).last_list_accounts_data
            #echo $gaia_cookie
            $last_username = $jsonFile.google.services.last_username
            #echo $last_username
            $hostName = $env:COMPUTERNAME
            If ($last_username ) {
                $extObj = new-object PSObject -property @{ComputerName=$hostName;WindowsUser=$user;SyncedUsername=$last_username}
                $chromePreferences += $extObj
            }
        }                
    }
}

$chromePreferences | Where-Object {$_.Name -ne $Null} | select-object -Property ComputerName, WindowsUser, SyncedUsername

$chromePreferences