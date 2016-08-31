function Import-CmdbSetting {
    # .SYNOPSIS
    #   Import the CMDB configuration for this host.
    # .DESCRIPTION
    #   If there is no saved configuration the CMDB will use a standalone 
    #   style with no external dependencies.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     14/07/2016 - Chris Dent - Added ability to marge settings from default to account for the addition of new settings to existing instances.
    #     06/07/2016 - Chris Dent - Created.

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param(
        [String]$Path = "$env:PROGRAMDATA\$($myinvocation.MyCommand.ModuleName -replace '\..+$')\$($myinvocation.MyCommand.ModuleName).json"
    )

    $defaultSettings = GetDefaultSettings

    if (Test-Path $Path) {
        $Script:settings = Get-Content $Path -Raw | ConvertFrom-Json

        # Add any missing settings.
        foreach ($property in $defaultSettings.PSObject.Properties) {
            if (-not $Script:settings.PSObject.Properties.Item($property.Name)) {
                Add-Member $property.Name $property.Value -InputObject $Script:settings
            }
        }        
    } else {
        Write-host "no settings in $Path"
        # If there is no configuration, return something that will let the application work to an extent.
        $Script:settings = $defaultSettings
    }
}