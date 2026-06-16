<#
.SYNOPSIS
Audit-CCNum-Text.ps1 

This script is designed to function like the PII scan modules found in Nessus & Nexpose. 
File Types scanned for possible CREDIT CARD data: 
- *.txt, *.csv, *.xml

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

####################
# TEXT Based files #
####################
function searchTextFiles() {
    Get-ChildItem -Recurse -file -path $searchPath -Include *.txt, *.csv, *.xml -Exclude *CCNumLuhnCheck.csv -ErrorAction $erroractionpref | 
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
searchTextFiles