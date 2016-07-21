CmdbItem DefaultRegionalSetting @{
    Get = {
        $keyboardLayout = @{
            0x402  = 'Bulgarian'
            0x405  = 'Czech'
            0x406  = 'Danish'
            0x407  = 'German-Standard'
            0x408  = 'Greek'
            0x409  = 'English-UnitedStates'
            0x40b  = 'Finnish'
            0x40a  = 'Spanish-TraditionalSort'
            0x40c  = 'French-Standard'
            0x40e  = 'Hungarian'
            0x40f  = 'Icelandic'
            0x410  = 'Italian-Standard'
            0x413  = 'Dutch-Standard'
            0x414  = 'Norwegian-Bokmal'
            0x415  = 'Polish'
            0x416  = 'Portuguese-Brazilian'
            0x418  = 'Romanian'
            0x419  = 'Russian'
            0x41a  = 'Croatian'
            0x41b  = 'Slovak'
            0x41d  = 'Swedish'
            0x41f  = 'Turkish'
            0x424  = 'Slovenian'
            0x807  = 'German-Swiss'
            0x809  = 'English-UnitedKingdom'
            0x80a  = 'Spanish-Mexican'
            0x80c  = 'French-Belgian'
            0x810  = 'Italian-Swiss'
            0x813  = 'Dutch-Belgian'
            0x814  = 'Norwegian-Nynorsk'
            0x816  = 'Portuguese-Standard'
            0xc07  = 'German-Austrian'
            0xc09  = 'English-Australian'
            0xc0a  = 'Spanish-ModernSort'
            0xc0c  = 'French-Canadian'
            0x1009 = 'English-Canadian'
            0x100c = 'French-Swiss'
            0x1409 = 'English-NewZealand'
            0x1809 = 'English-Irish'
        }

        try {
            $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::Users, $Node.ComputerName)
        } catch {
            Write-Error -ErrorRecord $_
        }
        
        if ($? -and $baseKey) {
            $internationalSetting = $baseKey.OpenSubKey(".DEFAULT\Control Panel\International")
            $defaultKeyboardLayout = $baseKey.OpenSubKey(".DEFAULT\Keyboard Layout\Preload")
            
            [PSCustomObject]@{
                Country               = $internationalSetting.GetValue("sCountry")
                CountryCode           = $internationalSetting.GetValue("iCountry")
                DefaultKeyboardLayout = $keyboardLayout[([Int32]"0x$($defaultKeyboardLayout.GetValue('1'))")]
                Language              = $internationalSetting.GetValue("sLanguage")
                Locale                = $internationalSetting.GetValue("LocaleName")
            }
        }
    }
}