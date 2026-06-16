<#
.SYNOPSIS
Audit-CCKeyTerms-AllFiles.ps1 

This script is designed to function like the PII scan modules found in Nessus & Nexpose. 
File Types scanned for possible CREDIT CARD data: 
- *.pdf

!!THIS SCRIPT ASSUMES PDFTOTEXT.EXE WILL BE IN $ENV:SYSTEMROOT!!

This script does depend on PDFtoText, which is not packaged with Kansa. 
You will have to download it.

.NOTES
!! Data is returned ONLY once a function has completed. Adding too many file extensions to one function    !!
!! may/WILL increase the amount of time it takes for data to be retured. If a remote host drops connecton  !!
!! before one of the functions completes, ** NO ** data will be returned.                                  !!

The following lines are required by Kansa.ps1. They are directives that
tell Kansa how to treat the output of this script and where to find the
binary that this script depends on.
OUTPUT csv
BINDEP .\Modules\bin\pdftotext.exe
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
searchPdfFiles