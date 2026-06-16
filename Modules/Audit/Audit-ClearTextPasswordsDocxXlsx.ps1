<#
.SYNOPSIS
Audit-CCKeyTerms-AllFiles.ps1 

This script is designed to function like the PII scan modules found in Nessus & Nexpose. 
File Types scanned for possible CREDIT CARD data: 
- *.docx
- *.xlsx

!!THIS SCRIPT ASSUMES 7Z.EXE, & 7Z.DLL WILL BE IN $ENV:SYSTEMROOT!!

This script does depend on 7zip, which id not packaged with Kansa. 
You will have to download it.

.NOTES
!! Data is returned ONLY once a function has completed. Adding too many file extensions to one function    !!
!! may/WILL increase the amount of time it takes for data to be retured. If a remote host drops connecton  !!
!! before one of the functions completes, ** NO ** data will be returned.                                  !!

The following lines are required by Kansa.ps1. They are directives that
tell Kansa how to treat the output of this script and where to find the
binary that this script depends on.
OUTPUT csv
BINDEP .\Modules\bin\7z.zip
#>
 
#Path to search recursively #$searchPath = "C:\"
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [string]$searchPath="C:\Users"  # if path not specified, audit C:\ drive 
)
#Error Action 
$erroractionpref = "SilentlyContinue"
#Generic CC Key Terms to Search for 
$pattern = @('Pass Word', 'Password','passwd','UserName', 'User Name', 'login', 'passphrase', 'secret', '@yahoo', '@gmail', '@outlook', '@yourdomain')

################
# WORD - .docx #
################
function searchWordFiles() {
Get-ChildItem -Recurse -file -Path $searchPath -Include *.docx -ErrorAction $erroractionpref | 
    ForEach-Object {
        $fullPath = $_.FullName
        $filename = $_.Name
        $unzippedPath = "$env:SystemRoot\unzipped"        
        $uncpath = "\\"+$env:COMPUTERNAME+"\"+$fullPath   #File's full path  
        $uncpath = $uncpath.Replace(':','$')              #Replace ':' with '$' to format the unc path   
        $uncpath = $uncpath.Replace($filename ,'')        #Replace the File's name in the unc path to display the Directory containing the file

        If(!(Test-Path -Path $unzippedPath)) {New-Item -Path $env:SystemRoot -Name "unzipped" -ItemType Directory}
        remove-item -Path "$unzippedPath\*" -Recurse -Force
        Start-Process -FilePath "$env:SystemRoot\7z.exe" -ArgumentList " x ""$fullPath"" -o""$unzippedPath"" -y" -Wait -WindowStyle Hidden
        Start-Sleep -Milliseconds 500    

        If (Test-Path -Path "$unzippedPath\word\document.xml") {    
            Select-String -pattern $pattern -Path "$unzippedPath\word\document.xml" |
            ForEach-Object {                     
                    Select-Object -InputObject $_ -Property @{Name = 'Path';Expression = {(Get-ChildItem -path $fullPath)}}, Filename,
                        @{Name = 'MatchedExpression';Expression = {("``  "+$_.Matches)}},
                        @{Name = 'BaseName';Expression = {(Get-ChildItem -Path $fullPath).BaseName}},
                        @{Name = 'Extension';Expression = {(Get-ChildItem -Path $fullPath).Extension}},
                        @{Name = 'Bytes';Expression = {(Get-ChildItem -Path $fullPath).Length}},
                        @{Name = 'CreationDate';Expression = {(Get-ChildItem -Path $fullPath).CreationTime}},
                        @{Name = 'LastWriteTime';Expression = {(Get-ChildItem -Path $fullPath).LastWriteTime}},
                        #@{Name = 'HostName';Expression = {$env:COMPUTERNAME }},  
                        #@{Name = 'UNCfilepath';Expression = {(("\\"+$env:COMPUTERNAME+"\"+($fullPath).Replace(':', '$') ))}},
                        @{Name = 'UNCpath';Expression = {$uncpath}}
            }
        }    
        remove-item -Path "$unzippedPath\*" -Recurse -Force
    }
}

#################
# Excel - .xlsx #
#################
function searchExcelFiles() {
    Get-ChildItem -Recurse -file -Path $searchPath -Include *.xlsx -ErrorAction $erroractionpref | 
    ForEach-Object {
        $fullPath = $_.FullName
        $filename = $_.Name
        $unzippedPath = "$env:SystemRoot\unzipped"
        $uncpath = "\\"+$env:COMPUTERNAME+"\"+$fullPath   #File's full path  
        $uncpath = $uncpath.Replace(':','$')              #Replace ':' with '$' to format the unc path   
        $uncpath = $uncpath.Replace($filename ,'')        #Replace the File's name in the unc path to display the Directory containing the file

        If(!(Test-Path -Path $unzippedPath)) {New-Item -Path $env:SystemRoot -Name "unzipped" -ItemType Directory}
        remove-item -Path "$unzippedPath\*" -Recurse -Force
        Start-Process -FilePath "$env:SystemRoot\7z.exe" -ArgumentList " x ""$fullPath"" -o""$unzippedPath"" -y" -Wait -WindowStyle Hidden
        Start-Sleep -Milliseconds 500

        If (Test-Path -Path "$unzippedPath\xl\*.xml") {    
            Get-ChildItem -Recurse -file -Path "$unzippedPath\xl\" -Include *.xml | Select-String -pattern $pattern |
            ForEach-Object { 
                    Select-Object -InputObject $_ -Property @{Name = 'Path';Expression = {(Get-ChildItem -path $fullPath)}}, Filename,
                        @{Name = 'MatchedExpression';Expression = {("``  "+$_.Matches)}},
                        @{Name = 'BaseName';Expression = {(Get-ChildItem -Path $fullPath).BaseName}},
                        @{Name = 'Extension';Expression = {(Get-ChildItem -Path $fullPath).Extension}},
                        @{Name = 'Bytes';Expression = {(Get-ChildItem -Path $fullPath).Length}},
                        @{Name = 'CreationDate';Expression = {(Get-ChildItem -Path $fullPath).CreationTime}},
                        @{Name = 'LastWriteTime';Expression = {(Get-ChildItem -Path $fullPath).LastWriteTime}},
                        #@{Name = 'HostName';Expression = {$env:COMPUTERNAME }},  
                        #@{Name = 'UNCfilepath';Expression = {(("\\"+$env:COMPUTERNAME+"\"+($fullPath).Replace(':', '$') ))}},
                        @{Name = 'UNCpath';Expression = {$uncpath}}  
            }
        }
        remove-item -Path "$unzippedPath\*" -Recurse -Force
    }
}


# Expand-Zip does what the name implies, here for reference, used below
Function Expand-Zip ($zipfile, $destination) {
	[int32]$copyOption = 16 # Yes to all
    $shell = New-Object -ComObject shell.application
    $zip = $shell.Namespace($zipfile)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item, $copyOption)
    }
}

#Start Script 
$zippath = ($env:SystemRoot + "\pii.zip")
if (Test-Path ($zippath)) {  
    #$suppress = New-Item -Name unzipped -ItemType Directory -Path $env:Temp -Force
    $zipdest = $env:SystemRoot
    Expand-Zip $zippath $zipdest
    if (Test-Path($zipdest + "\7z.exe")) {
        #If unzipped run functions to search files 
        searchWordFiles
        searchExcelFiles
    } else {
        "pii.zip found, but not unzipped."
    }
} else {
    "pii.zip not found on $env:COMPUTERNAME"
}
