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
    param( )

    $defaultSettings = GetDefaultSettings

    $moduleName = $myinvocation.MyCommand.ModuleName
    $path = "$env:PROGRAMDATA\$($moduleName -replace '\..+$')\$moduleName.json"
    if (Test-Path $path) {
        $Script:settings = Get-Content $path -Raw | ConvertFrom-Json

        # Add any missing settings.
        $defaultSettings.PSObject.Properties | ForEach-Object {
            if (-not $Script:settings.PSObject.Properties.Item($_.Name)) {
                Add-Member $_.Name $_.Value -InputObject $Script:settings
            }
        }        
    } else {
        # If there is no configuration, return something that will let the application work to an extent.
        $Script:settings = $defaultSettings
    }
}