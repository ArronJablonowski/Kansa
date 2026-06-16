<#
.SYNOPSIS
Audit-ClearTextPasswordsDocXls.ps1 

This script is designed to function like the PII scan modules found in Nessus & Nexpose. 
File Types scanned for possible CREDIT CARD data: 
- *.doc, *.xls

.NOTES
!! Data is returned ONLY once a function has completed. Adding too many file extensions to one function    !!
!! may/WILL increase the amount of time it takes for data to be retured. If a remote host drops connecton  !!
!! before one of the functions completes, ** NO ** data will be returned.                                  !!

#>
 
#Path to search recursively #$searchPath = "C:\"
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [string]$searchPath="C:\"  # if path not specified, audit C:\ drive 
)
#Error Action 
$erroractionpref = "SilentlyContinue"
#Generic CC Key Terms to Search for 
$pattern = @('Pass Word', 'Password','passwd','root','UserName', 'User Name', 'login', 'passphrase', 'secret', '@yahoo', '@gmail', '@outlook', '@yourdomain')

############################################
# TEXT Based files & OLD MS OFFICE Formats #
############################################
function searchTextFiles() {
    Get-ChildItem -Recurse -file -path $searchPath -Include *.doc, *.xls -Exclude *CCNumLuhnCheck.csv -ErrorAction $erroractionpref | 
    ForEach-Object { Select-String -pattern $pattern -Path $PSItem.FullName | 
        ForEach-Object { 
                $uncpath = "\\"+$env:COMPUTERNAME+"\"+$PSItem.Path   #File's full path  
                $uncpath = $uncpath.Replace(':','$')                 #Replace ':' with '$' to format the unc path   
                $uncpath = $uncpath.Replace($PSItem.Filename,'')     #Replace the File's name in the unc path to display the Directory containing the file
                Select-Object -InputObject $PSItem -Property Path, Filename,   
                    @{Name = 'MatchedExpression';Expression = {("``  "+ $PSItem.Matches)}},
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
searchTextFiles