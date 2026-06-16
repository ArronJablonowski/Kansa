# This script will pull the default search engine listed in the chrome preferences file. 
#
#
#
#

#$prefPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
#$pref = Get-Content $prefPath -Raw | ConvertFrom-Json
#$pref.default_search_provider.name
#$pref.default_search_provider.search_url

$prefPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
if (Test-Path $prefPath) {
    $pref = Get-Content $prefPath -Raw | ConvertFrom-Json
    $homepage = $pref.homepage
}
else {
    Write-Host "Chrome Preferences file not found."
}

echo $homepage