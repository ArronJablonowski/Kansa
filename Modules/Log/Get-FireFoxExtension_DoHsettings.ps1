<#
.SYNOPSIS
Get-FireFoxDoHSettings.ps1 
    Check the DoH settings of FireFox
.NOTES

#>

#Make an array to hold the extension objects 
$listDoH = @()
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
            $extensionJsFile = "$folder\$profile\prefs.js"
            #write-Host $extensionJsFile
            If (test-path $extensionJsFile) {
                #Write-Host $extensionJsFile
                # Get-Content -Raw -Path $extensionJsFile | ConvertFrom-Json | ForEach-Object                
                #$jsFile =  Select-String -pattern "*network.trr.mode*"
                
                $SEL = Select-String -Path $extensionJsFile -Pattern "network.trr.mode"
                if($SEL -ne $null){ # If NTM is found in file
                    foreach($line in Get-Content $extensionJsFile) {
                        #echo $line
                        $ntm = "network.trr.mode"
                        if($line -match $ntm){
                            $mode = $line.Split(',')
                            $DoHMode = ($mode[1]).Split(')')[0]
                            if($DoHMode -match 0){ 
                                $DoHMode = "DoH Off - Use Native DNS"
                            }
                            elseif ($DoHMode -match 2){ 
                                $DoHMode = "Use DoH, fallback on DNS"
                            }
                            elseif ($DoHMode -match 3){ 
                                $DoHMode = "Use DoH Only"
                            }
                            elseif ($DoHMode -match 5){ 
                                $DoHMode = "turned off, no remote changes"
                            }
                            else {
                                $DoHMode = "unknown"
                            }
                            $extObj = new-object PSObject -property @{Host=$env:COMPUTERNAME;WindowsUser=$user;Mode=$DoHMode;Raw=$line}
                            $listDoH += $extObj #add the extension object to the list of extensions array 
                        }    
                    } 
                }
                else{
                    $DoHMode = "Network TRR mode Not Found"
                    $line = "NA"
                    $extObj = new-object PSObject -property @{Host=$env:COMPUTERNAME;WindowsUser=$user;Mode=$DoHMode;Raw=$line}
                    $listDoH += $extObj #add the extension object to the list of extensions array
                }
            }
            }

        }
            
            #$result = checkExtensionName $extension
            #make a new PS object for each extension and assign the object's properties  
            #$extObj = new-object PSObject -property @{Extension=$extension;Name=$result;WindowsUser=$user}
            #$listOfExtensions += $extObj
        }        
    

$listDoH | select-object -Property Host, WindowsUser, Mode, Raw
