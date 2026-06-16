<#
.SYNOPSIS
Audit-CCNumLuhnCheck.ps1 

This script is designed to function like the PII scan modules found in Nessus & Nexpose. 
File Types scanned for possible CREDIT CARD data: 
- *.txt, *.csv, *.doc, *.xls
- *.docx
- *.xlsx
- *.pdf

!!THIS SCRIPT ASSUMES 7Z.EXE, 7Z.DLL, & PDFTOTEXT.EXE WILL BE IN $ENV:SYSTEMROOT!!

This script does depend on 7zip & PDFtoText, which are not packaged with Kansa. 
You will have to download them.

.NOTES
!! Data is returned ONLY once a function has completed. Adding too many file extensions to one function    !!
!! may/WILL increase the amount of time it takes for data to be retured. If a remote host drops connecton  !!
!! before one of the functions completes, ** NO ** data will be returned.                                  !!

The following lines are required by Kansa.ps1. They are directives that
tell Kansa how to treat the output of this script and where to find the
binary that this script depends on.
OUTPUT csv
BINDEP .\Modules\bin\pii.zip
#>
 
#Path to search recursively #$searchPath = "C:\"
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [string]$searchPath="C:\"  # if path not specified, audit C:\ drive 
)
#Error Action 
$erroractionpref = "SilentlyContinue"
$pattern = @(
    #Generic CC numbers
    '[4|5|3|6][0-9]{15}|[4|5|3|6][0-9]{3}[-| ][0-9]{4}[-| ][0-9]{4}[-| ][0-9]{4}',
    #Visa, Discover, and MasterCard 
    '[456][0-9]{3}[-| ][0-9]{4}[-| ][0-9]{4}[-| ][0-9]{4}',
    #American Express
    '3[47][0-9]{13}","3[47][0-9]{2}[-| ][0-9]{6}[-| ][0-9]{5}',
    '^3[47][0-9]{13}$',
    #Visa
    '^4[0-9]{12}(?:[0-9]{3})?$',
    '([^0-9\.-]|^)(4[0-9]{3}( |-|)([0-9]{4})( |-|)([0-9]{4})( |-|)([0-9]{4}))([^0-9\.-]|$)',
    #MasterCard
    '^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}$',
    '([^0-9\.-]|^)((222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[0-1][0-9]|2720|5[1-5][0-9]{2})( |-|)([0-9]{4})( |-|)([0-9]{4})( |-|)([0-9]{4}))([^0-9\.-]|$)',
    #Discover 
    '^6(?:011|5[0-9]{2})[0-9]{12}$',
    '([^0-9\.-]|^)((6011|6[45][0-9]{2})( |-|)[0-9]{4}( |-|)[0-9]{4}( |-|)[0-9]{4})([^0-9\-]|$)'
)

#Luhn Check for Found CC Numbers - This will cut down on the false positives 
function LuhnCheck($number) { 
    If(-not ([string]::IsNullOrEmpty($number))) {
        $number = $number.Trim();
        $number = $number.replace(' ','');
        $number = $number.replace('-',''); 
        $number = $number.replace('|','');
        $number = $number -replace '[^0-9]'
        $temp = $Number.ToCharArray();
        $numbers = @(0) * $Number.Length;
        $alt = $false;
        for($i = $temp.Length -1; $i -ge 0; $i--) {
        $numbers[$i] = [int]::Parse($temp[$i])
        if($alt){
            $numbers[$i] *= 2
            if($numbers[$i] -gt 9) { 
                $numbers[$i] -= 9 
            }
        }
        $sum += $numbers[$i]
        $alt = !$alt
        }
        return ($sum % 10) -eq 0
    }
}

############################################
# TEXT Based files & OLD MS OFFICE Formats #
############################################
function searchTextFiles() {
    Get-ChildItem -Recurse -file -path $searchPath -Include *.txt, *.csv, *.xml, *.doc, *.xls -Exclude *CCNumLuhnCheck.csv -ErrorAction $erroractionpref | 
    ForEach-Object { Select-String -pattern $pattern -Path $PSItem.FullName | 
        ForEach-Object { 
            if (LuhnCheck($PSItem.Matches).Value -eq $true){ 
                $uncpath = "\\"+$env:COMPUTERNAME+"\"+$PSItem.Path   #File's full path  
                $uncpath = $uncpath.Replace(':','$')                 #Replace ':' with '$' to format the unc path   
                $uncpath = $uncpath.Replace($PSItem.Filename,'')     #Replace the File's name in the unc path to display the Directory containing the file
                Select-Object -InputObject $PSItem -Property Path, Filename,   
                    @{Name = 'MatchedExpression';Expression = {("``  "+ $PSItem.Matches)}},
                    @{Name = 'PassedLuhnCheck';Expression = {(LuhnCheck($PSItem.Matches).Value)}},  
                    @{Name = 'BaseName';Expression = {(Get-ChildItem -Path $PSItem.Path).BaseName}},
                    @{Name = 'Extension';Expression = {(Get-ChildItem -Path $PSItem.Path).Extension}},
                    @{Name = 'Bytes';Expression = {(Get-ChildItem -Path $PSItem.Path).Length}},
                    @{Name = 'CreationDate';Expression = {(Get-ChildItem -Path $PSItem.Path).CreationTime}},
                    @{Name = 'LastWriteTime';Expression = {(Get-ChildItem -Path $PSItem.Path).LastWriteTime}},             
                    #@{Name = 'HostName';Expression = {$env:COMPUTERNAME }},
                    #@{Name = 'UNCfilepath';Expression = {(("\\"+$env:COMPUTERNAME+"\"+($fullPath).Replace(':', '$') ))}},
                    @{Name = 'UNCpath';Expression = {$uncpath}}                
            }
        }
    }
}

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
                if (LuhnCheck($_.Matches).Value -eq $true){                     
                    Select-Object -InputObject $_ -Property @{Name = 'Path';Expression = {(Get-ChildItem -path $fullPath)}}, Filename,
                        @{Name = 'MatchedExpression';Expression = {("``  "+$_.Matches)}},
                        @{Name = 'PassedLuhnCheck';Expression = {(LuhnCheck($_.Matches).Value)}}, 
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
                if (LuhnCheck($_.Matches).Value -eq $true){ 
                    Select-Object -InputObject $_ -Property @{Name = 'Path';Expression = {(Get-ChildItem -path $fullPath)}}, Filename,
                        @{Name = 'MatchedExpression';Expression = {("``  "+$_.Matches)}},
                        @{Name = 'PassedLuhnCheck';Expression = {(LuhnCheck($_.Matches).Value)}}, 
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
        }
        remove-item -Path "$unzippedPath\*" -Recurse -Force
    }
}

####################
# PDF Files - .pdf #
####################

function searchPdfFiles() {
    Get-ChildItem -Recurse -file -Path $searchPath -Include *.pdf -ErrorAction $erroractionpref | 
    ForEach-Object {
        $fullPath = $_.FullName
        $filename = $_.Name
        $unzippedPath = "$env:SystemRoot\unzipped"
        $uncpath = "\\"+$env:COMPUTERNAME+"\"+$fullPath   #File's full path  
        $uncpath = $uncpath.Replace(':','$')              #Replace ':' with '$' to format the unc path   
        $uncpath = $uncpath.Replace($filename ,'')        #Replace the File's name in the unc path to return the Directory containing the file

        If(!(Test-Path -Path $unzippedPath)) {New-Item -Path $env:SystemRoot -Name "unzipped" -ItemType Directory} # make dir named "unzipped" if it does not exist
        remove-item -Path "$unzippedPath\*" -Recurse -Force #remove any old data

        Start-Process -FilePath "$env:SystemRoot\pdftotext.exe" -ArgumentList " ""$fullPath"" ""$unzippedPath\pdfFile.txt"" " -Wait -WindowStyle Hidden  # ~.exe  "pfdFilePAth.pdf" --  pdftotext.exe "' & $file & '" ' & @ScriptDir &'\temp\pdf\tempPDF.txt', @ScriptDir, @SW_HIDE) 
        Start-Sleep -Milliseconds 500
        
        If (Test-Path -Path "$unzippedPath\pdfFile.txt") {    
            Get-ChildItem -Recurse -file -Path "$unzippedPath\pdfFile.txt" | Select-String -pattern $pattern |
            ForEach-Object { 
                if (LuhnCheck($_.Matches).Value -eq $true){ 
                    Select-Object -InputObject $_ -Property @{Name = 'Path';Expression = {(Get-ChildItem -path $fullPath)}}, Filename,
                        @{Name = 'MatchedExpression';Expression = {("``  "+$_.Matches)}},
                        @{Name = 'PassedLuhnCheck';Expression = {(LuhnCheck($_.Matches).Value)}}, 
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
searchTextFiles
$zippath = ($env:SystemRoot + "\pii.zip")
if (Test-Path ($zippath)) {  
    #$suppress = New-Item -Name unzipped -ItemType Directory -Path $env:Temp -Force
    $zipdest = $env:SystemRoot
    Expand-Zip $zippath $zipdest
    if (Test-Path($zipdest + "\7z.exe")) {   
        searchWordFiles
        searchExcelFiles
        searchPdfFiles
    } else {
        "pii.zip found, but not unzipped."
    }
} else {
    "pii.zip not found on $env:COMPUTERNAME"
}

#Where-Object { findstr.exe /mprc:. $PSItem.FullName } | 

###################
# B.E.R.T. Lives. #
###################