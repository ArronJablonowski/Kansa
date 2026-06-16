<#
.SYNOPSIS
Get-SharePermissions.ps1 enumerates the SMB shares on the target host and lists
the share and NTFS access rights for them.
.NOTES
OUTPUT TSV
#>
[CmdletBinding()]
Param(

)

If (Get-Command Get-SmbShare -ErrorAction SilentlyContinue) {
    foreach ($share in (Get-SmbShare -ErrorAction SilentlyContinue))
    {
        $shareName = $share.Name
        Write-Verbose "Grabbing share rights for $shareName"

        if ([string]::IsNullOrWhiteSpace($share.Path)) {
            Write-Warning "Share '$shareName' does not expose a filesystem path. Skipping NTFS permission collection for this share."
            continue
        }

        try {
            $shareAcl = Get-Acl -Path $share.Path -ErrorAction Stop
            $shareOwner = $shareAcl.Owner
        }
        catch {
            Write-Warning "Unable to read ACL for share '$shareName' at '$($share.Path)': $($_.Exception.Message)"
            continue
        }
    
        $o = "" | Select-Object Share, Path, Source, User, Type, IsOwner, Full, Write, Read, Other
        $o.Share = $share.Name
        $o.Path = $share.Path

        foreach ($smbPerm in (Get-SmbShareAccess -Name $share.Name -ErrorAction SilentlyContinue))
        {
            $o.Source = "SMB"
            $o.User = $smbPerm.AccountName
            $o.Type = $smbPerm.AccessControlType
            $o.IsOwner = $shareOwner -match ($smbPerm.AccountName -replace "\\", "\\")
            $o.Full = $smbPerm.AccessRight -match "Full"
            $o.Write = $smbPerm.AccessRight -match "(Full|Change)"
            $o.Read = $smbPerm.AccessRight -match "(Full|Change|Read)"
            $o.Other = $smbPerm.AccessRight -notmatch "(Full|Change|Read)"

            $o
        }
    
        foreach ($aclPerm in (($shareAcl.AccessToString).Split("`n")))
        {
            $aclPermParts = $aclPerm -split "(Allow|Deny)"
            if ($aclPermParts.Count -lt 3) {
                Write-Warning "Unable to parse ACL entry for share '$shareName': $aclPerm"
                continue
            }

            $aclRights = ($aclPermParts[2].Trim() -split ",").Trim()
        
        
            $o.Source = "ACL"
            $o.User = $aclPermParts[0]
            $o.Type = $aclPermParts[1]
            $o.IsOwner = $shareOwner -match ($aclPermParts[0].Trim() -replace "\\", "\\")
            $o.Full = $o.Write = $o.Read = $o.Other = $False

            # The way ACL entries are written out as a string is...odd. I would
            # have preferred to use SDDL output, but parsing it lead me down too
            # many rabbit holes.
            while($aclRights)
            {
                $aclRight, $aclRights = $aclRights

                switch ($aclRight)
                {
                    "FullControl" { $o.Full  = $o.Write = $o.Read = $True; break }
                    "Write"       { $o.Write = $True; break }
                    "Read"        { $o.Read  = $True; break }
                    default       { $o.Other = $True }
                }
            }

            $o
        }
    }
}
else {
    Write-Warning "Get-SmbShare is not available on this host. Share permissions were not collected."
}
