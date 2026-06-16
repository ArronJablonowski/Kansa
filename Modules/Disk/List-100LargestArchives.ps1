<#
.SYNOPSIS
List-100LargestArchives.ps1
   
This module will list out the 100 Largest Archives on a system via file extension. 
  
#>

$SearchLocation = "C:\"
Get-ChildItem -path $SearchLocation -Include *.zip, *.7z, *.rar, *.tar, *.tar.gz, *.tgz, *.tar.Z, *.tar.bz2, *.tbz2, *.tar.lzma, *.tlz., *.tar.xz, *.txz, *.iso, *.txz, *.tlz*, *.dmg, *.dd, *.b2z, *.gz, *.gzip, *.xz, *.s7z, *.cab, *.car, *.dar, *.dgc, *.ear, *.war, *.sqx, *.xar, *.zipx, *.pim, *.apk, *.alz, *.ace, *.raw, *.aff4, *.img -Recurse | Sort-Object Length -desc | Select-Object name, length, Extension, BaseName, fullname, CreationTime, LastWriteTime, LastAccessTime -f 100 
