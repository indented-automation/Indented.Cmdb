CmdbItem LocalAccount.User @{
    Get = {
        if (-not ('UserFlags' -as [Type])) {
            Add-Type '
                [System.FlagsAttribute()]
                public enum UserFlags : int
                {
                    Script                             = 1,
                    AccountDisable                     = 2,
                    HomeDirectoryRequired              = 8,
                    LockedOut                          = 16,
                    PasswordNotRequired                = 32,
                    PasswordCannotChange               = 64,
                    EncryptedTextPasswordAllowed       = 128,
                    TemporaryDuplicateAccount          = 256,
                    NormalAccount                      = 512,
                    InterdomainTrustAccount            = 2048,
                    WorkstationTrustAccount            = 4096,
                    ServerTrustAccount                 = 8192,
                    DoNoExpirePassword                 = 65536,
                    MNSLogonAccount                    = 131072,
                    SmartcardRequired                  = 262144,
                    TrustedForDelegation               = 524288,
                    NotDelegated                       = 1048576,
                    UseDESKeyOnly                      = 2097152,
                    DoNotRequirePreAuth                = 4194304,
                    PasswordExpired                    = 8388608,
                    TrustedToAuthenticateForDelegation = 16777216
                }
            '
        }

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
                $null = $directoryEntry.Get('name')
            } catch {
                $isDomainController = $false
            }
            $directoryEntry = $null
            if (-not $isDomainController) {
                ([ADSI]('WinNT://{0}' -f $Node.Name)).Children.Where( { $_.SchemaClassName -eq 'User' } ) | ForEach-Object {
                    $lastLogin = $null
                    if ($_.LastLogin[0] -is [DateTime]) {
                        $lastLogin = $_.LastLogin[0]
                    }
                    $passwordAge = $null
                    if ($_.PasswordAge[0] -gt 0) {
                        $passwordAge = New-TimeSpan -Seconds $_.PasswordAge[0]
                    }

                    [PSCustomObject]@{
                        Name        = $_.Name[0]
                        FullName    = $_.FullName[0]
                        Description = $_.Description[0]
                        UserFlags   = ([UserFlags]$_.UserFlags[0]).ToString()
                        LastLogin   = $lastLogin
                        PasswordAge = $passwordAge
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