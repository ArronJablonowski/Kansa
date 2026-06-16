<#
.SYNOPSIS
List-100LargestFiles.ps1
   
This module will list out the 100 Largest Files on a system. 
  
#>

$SearchLocation = "C:\"
gci $SearchLocation -r | Sort-Object Length -desc | Select-Object Name, length, Extension, BaseName, fullname, CreationTime, LastWriteTime, LastAccessTime -f 100 