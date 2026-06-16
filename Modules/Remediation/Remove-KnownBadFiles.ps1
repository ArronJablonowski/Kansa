<#
    This script will delete files listed in the file array. 
    - Aka: Delete Files from a List (Array) of Known Bad Files in our Enviornment
    !! BE CAREFUL NOT TO DELETE THE WRONG THING !!

#>

#List of files to delete IF found on host. 
$fileArray = @("C:\drivers\temp\FileZilla_3.28.0_win64-setup_bundled.exe", 
               "C:\drivers\temp\*_bundled.exe",
               "C:\drivers\temp\FileZilla_3.28.0_win64-setup_bundled.exe",
               "C:\drivers\temp\testFile.txt", 
               "C:\Downloads\Image for Dell R630\Desktop\SetupImgBurn_2.5.8.0.exe",
               "C:\Downloads\Desktop\SetupImgBurn_2.5.8.0.exe")

#Delete Files 
for($i = 0; $i -lt $fileArray.Count; $i++) { #for each TLD in the $tldArray 
    $removeFile = $fileArray[$i]
    If(Test-Path $removeFile){
        Remove-Item $removeFile -Force
    }
}    