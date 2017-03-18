CmdbItem LocalAccount.Group @{
    Get = {
        # Connection test
        $isAvailable = $true
        $directoryEntry = [ADSI]('WinNT://{0}' -f $Node.Name)
        try {
            $null = $directoryEntry.Get('name')
        } catch {
            $isAvailable = $false
        }
        if ($isAvailable) {        
            # If this is not a domain controller
            $isDomainController = $true
            $directoryEntry = [ADSI]('WinNT://{0}/{0}$' -f $Node.Name)
            try {
                $null = $directoryEntry.Get("name")
            } catch {
                $isDomainController = $false
            }
            $directoryEntry = $null
            if (-not $isDomainController) {
                ([ADSI]('WinNT://{0}' -f $Node.Name)).Children.Where( { $_.SchemaClassName -eq 'Group' } ) | ForEach-Object {
                    [PSCustomObject]@{
                        Name        = $_.Name[0]
                        Description = $_.Description[0]
                        ObjectSid   = (New-Object System.Security.Principal.SecurityIdentifier(
                            [Byte[]]$_.objectSid[0],
                            0
                        )).ToString()
                    }
                }
            }
        }
    }
}