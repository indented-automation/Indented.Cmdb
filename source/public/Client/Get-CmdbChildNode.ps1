function Get-CmdbChildNode {
    # .SYNOPSIS
    #   Inflexible child searcher. First pass, solves immediate need.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     23/08/2016 - Chris Dent - Created.

    param(
        [String]$SiteName,

        [ValidateSet('PSObject', 'Tree')]
        [String]$OutputFormat = 'PSObject'
    )

    # Need some better way of storing dependency relationships. This is a start, nothing more.
    if ($OutputFormat -eq 'Tree') {
        Write-Host ('Site: {0}' -f $SiteName) -ForegroundColor Green
    }

    # This is the physical layer
    Get-CmdbNode -Filter "Node.SiteName -eq '$SiteName'" | ForEach-Object {
        $parent = $_

        if ($OutputFormat -eq 'Tree') {
            if ($_.Node.ChassisName) {
                Write-Host ('    {0} ({1})' -f $parent.Node.Name, $_.Node.ChassisName) -ForegroundColor Cyan
            } else {
                Write-Host ('    {0}' -f $parent.Node.Name) -ForegroundColor Cyan
            }
        }

        $hasChildren = $false
        if ($parent.Node.Type -in 'HyperVVirtualMachineHost', 'VMWareVirtualMachineHost') {
            Get-CmdbNode -Filter "VirtualInfrastructure.Guest.VMHost -eq '$($_.VirtualInfrastructure.Host.Name)'" | 
                Group-Object { $parent.Node.ServiceName } | ForEach-Object {
                    $hasChildren = $true

                    if ($OutputFormat -eq 'Tree') {
                        if ($_.Name -ne '') {
                            Write-Host ('        {0}' -f $_.Name) -ForegroundColor Yellow
                            foreach ($record in $_.Group) {
                                Write-Host ('            {0}' -f $record.Node.Name) -ForegroundColor White
                            }
                        } else {
                            foreach ($record in $_.Group) {
                                Write-Host ('        {0}' -f $record.Node.Name) -ForegroundColor White
                            }
                        }
                    }

                    foreach ($record in $_.Group) {
                        if ($OutputFormat -eq 'PSObject') {
                            [PSCustomObject]@{
                                Name        = $record.Node.Name
                                HasChildren = $false
                                IsPhysical  = $false
                                ServiceName = $record.Node.ServiceName
                                VMHost      = $parent.Node.Name
                                SiteName    = $SiteName
                            }
                        }
                    }
                }
        }

        [PSCustomObject]@{
            Name        = $parent.Node.Name
            HasChildren = $hasChildren
            IsPhysical  = $true
            ServiceName = $parent.Node.ServiceName
            VMHost      = $null
            SiteName    =  $SiteName
        }
    }
}