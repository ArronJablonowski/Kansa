<#
This application will find the versions of chocolatey installe d on a system 
#>
$choco  = New-Object -TypeName psobject 
$chocoVersion = C:\ProgramData\chocolatey\choco.exe -v
if(-not($chocoVersion)){ 
    #Write-Output "Seems Chocolatey is not installed, installing now"
    # Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    $chocoVersion = "None"
}
#elseif(test-path "C:\ProgramData\chocolatey\choco.exe"){

#}
#else{
 #   $chocoVersion  = "None"
#}

$choco | Add-Member -MemberType NoteProperty -Name Version -Value $chocoVersion

$choco
