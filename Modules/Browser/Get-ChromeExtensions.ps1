# get host name 
$hostname = $env:COMPUTERNAME

#Make an array to hold the extension objects 
$listOfExtensions = @()
# Get the Chrome Extension folder listing for each user 
$users = Get-ChildItem C:\Users

foreach ($user in $users){
    $Extensions = $($user.FullName)+"\AppData\Local\Google\Chrome\User Data\Default\Extensions"
    $SyncExtensions = $($user.FullName)+"\AppData\Local\Google\Chrome\User Data\Default\Sync Extension Settings"
    If(Test-Path $Extensions){ # Check that the path exists for the user
        foreach($extensionID in (Get-ChildItem $Extensions)){ # $extension = jibberish folder name of extension. ex: cjpalhdlnbpafiamejdnhcphjbkeiagm - uBlock Origin
             # If the Extension ID exists in "Sync Extension Settings, then its a Synced extension"
            If (Test-Path "$SyncExtensions\$extensionID"){ $synced = "SYNCED_EXT" } Else{ $synced = "not synced" }
            foreach($extVersion in (Get-ChildItem $extensionID.FullName)){  #  Extension's Version Folder(s)
                $versionFolderPath = $extVersion.FullName
                $manifestDotJson = "$versionFolderPath\manifest.json" # Extensions's Manifest dot Json file  
                If(Test-Path $manifestDotJson){ # Check if Manifest Json file exists 
                    $jsonObject = Get-Content $manifestDotJson | ConvertFrom-Json
                    $extensionName = $jsonObject.name
                    if($extensionName -notlike "__MSG*"){
                        $extObj = new-object PSObject -property @{ExtensionID=$extensionID;ExtensionName=$extensionName;ExtensionVersion=$extVersion;HostName=$hostname;WindowsUser=$user;Sync=$synced}
                        $listOfExtensions += $extObj #add the extension object to the list of extensions array
                    }Else{
                        $Id = ($extensionName -replace '__MSG_','').Trim('_')
                        # Messages dot Json files contain extension's Name based on __MSG_* value.  
                        $localesPath_en_messages = "$versionFolderPath\_locales\en\messages.json"
                        $localesPath_en_US_messages = "$versionFolderPath\_locales\en_US\messages.json"
                        If(Test-Path $localesPath_en_messages){ # _locales\en
                            $jsonObject = Get-Content $localesPath_en_messages | ConvertFrom-Json
                            $extensionName = $jsonObject.$Id.message | Select-Object -First 1
                        }ElseIf(Test-Path $localesPath_en_US_messages){ # _locales\en_US 
                            $jsonObject = Get-Content $localesPath_en_US_messages | ConvertFrom-Json
                            $extensionName = $jsonObject.$Id.message | Select-Object -First 1
                        }Else{
                            # No Messages files were found. 
                            $extensionName = "!! Unknown !!"
                        }
                        $extObj = new-object PSObject -property @{ExtensionID=$extensionID;ExtensionName=$extensionName;ExtensionVersion=$extVersion;HostName=$hostname;WindowsUser=$user;Sync=$synced}
                        $listOfExtensions += $extObj #add the extension object to the list of extensions array
                    }
                }
                Else{
                    $extensionName = "Json Manifest File Missing"
                    $extObj = new-object PSObject -property @{ExtensionID=$extensionID;ExtensionName=$extensionName;ExtensionVersion=$extVersion;HostName=$hostname;WindowsUser=$user;Sync=$synced}
                    $listOfExtensions += $extObj #add the extension object to the list of extensions array
                }
            }         
        }        
    }
}


$listOfExtensions | select-object -Property HostName, ExtensionID, ExtensionName, ExtensionVersion, WindowsUser, Sync