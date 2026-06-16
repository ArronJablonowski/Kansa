<#
.SYNOPSIS
Get-ProcImgPath maps processes to their files on disk. 

.NOTES
#>

# collect the process list, then loop through the list
$proc = @()
$wsproclist = @()
Foreach ($proc in get-process){
    try{
        # hash the executable file on disk
        $hash = Get-FileHash $proc.path -Algorithm SHA1 -ErrorAction stop
        $p = $proc
        $p | add-member -membertype noteproperty -name FileHash -value $hash.hash
        $p | add-member -membertype noteproperty -name HashAlgo -value $hash.Algorithm
        $p | Add-Member -MemberType NoteProperty -name PSComputerName -Value $env:ComputerName
        $wsproclist += $p
        }
    catch{
        # error handling.  If the file can't be hashed - either it's not there or we don't have rights to it
        $p = $proc 
        $p | Add-Member -MemberType NoteProperty -name PSComputerName -Value $env:ComputerName
        $p | Add-Member -MemberType NoteProperty -name FileHash -Value 'Permission Denied or Missing File' -Force
        $wsproclist += $p
        }
}
$wsproclist | select-object PSComputerName,Id,ProcessName,Path,FileHash,FileVersion,Product,ProductVersion,HashAlgo #| export-csv domain-wide-tasks.csv
