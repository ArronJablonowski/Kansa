<#
.SYNOPSIS
Get-FireFoxExtensionListing.ps1 
    This script will list out the FireFox extensions found in user's appdata folder  
        %AppData%\Roaming\Mozilla\Firefox\Profiles\*\extensions.json >>> *.default\extensions.json & *.default-release  
    It will then attempt to ID the extension against a list of "knonwn" firefox extensions from the chrome store.
    *Please not this is base solely on folder nameing convention. Althought it has proven fairly reliable, 
    it is trivial to spoof another externsion's folder name. 
.NOTES

#>

# $knownChromeExtensions = @{ }
# Function to check if the extension is in the known extensions hashtable (above). 
function checkExtensionName($extensionName) {   
    #Check if hash table contains the extension 
    If ($knownChromeExtensions.ContainsKey("$extensionName")) {
        $extensionDesc = $knownChromeExtensions.get_item("$extensionName")
        return $extensionDesc
    }
    Else{ # Extension is Unknown 
        return " !! Unknown Extension !! "
    }
}

#Make an array to hold the extension objects 
$listOfExtensions = @()
# Get the FireFox Extension listing for each user - %AppData%\Roaming\Mozilla\Firefox\Profiles\*\extensions.json >>> *.default\extensions.json & *.default-release  
$users = Get-ChildItem C:\Users
# ForEach User in Users dir 
foreach ($user in $users){
    #Get a list of FF profiles for each windows user 
    $listedUser = $user 
    $folder = $($user.FullName)+"\AppData\Roaming\Mozilla\Firefox\Profiles"
    If(Test-Path $folder){
        $profileFolder = Get-ChildItem $folder #  Profiles\*.default\extensions.json & *.default-release
        foreach($profile in $profileFolder) {
            $extensionJsonFile = "$folder\$profile\extensions.json"
            If (test-path $extensionJsonFile) {
                # Write-Host $extensionJsonFile
                # Get-Content -Raw -Path $extensionJsonFile | ConvertFrom-Json | ForEach-Object                
                $jasonFile = Get-Content -Raw -Path $extensionJsonFile | ConvertFrom-Json
                $jasonFile.addons | ForEach-Object{
                    Select-Object -InputObject $_ -Property @{Name = 'name';Expression = {(($_.defaultLocale).name)}},
                    id, syncGUID, version, type, path,
                    @{Name = 'User';Expression = {($listedUser)}}, 
                    @{Name = 'ExtensionDesc';Expression = {(($_.defaultLocale).description)}},
                    @{Name = 'creator';Expression = {(($_.defaultLocale).creator)}},
                    @{Name = 'homepage';Expression = {(($_.defaultLocale).homepageURL)}}, sourceURI,
                    visible, active, userDisabled, appDisabled, hidden, installDate, updateDate, applyBackgroundUpdates, 
                    releaseNotesURI, softDisabled, foreignInstall, strictCompatibility, rootURI, location 
}

            }
            
            #$result = checkExtensionName $extension
            #make a new PS object for each extension and assign the object's properties  
            #$extObj = new-object PSObject -property @{Extension=$extension;Name=$result;WindowsUser=$user}
            #$listOfExtensions += $extObj
        }        
    }
}

#$listOfExtensions | select-object -Property Name, Extension, WindowsUser