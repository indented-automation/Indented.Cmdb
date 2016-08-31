function Get-CmdbParentNode {
    # .SYNOPSIS
    #   Geneate a dependency tree.
    # .DESCRIPTION
    #   This follows dependencies down a chain.
    #   Dependencies need describing in both directions
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     22/08/2016 - Chris Dent - Created. 

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Filter,

        [Parameter(DontShow = $true)]
        [Int]$level = 1
    )
    
    Get-CmdbNode $NodeName | ForEach-Object {
        $record = $_

        if ($level -eq 1) {
            if ($record.Node.ServiceName) {
                Write-Host ('{0} ({1})' -f $record.Node.Name, $record.VirtualInfrastructure.Guest.ServiceName) -ForegroundColor Green
            } else {
                Write-Host ('{0}' -f $record.Node.Name) -ForegroundColor Green
            }
        }

        Get-CmdbItem | ForEach-Object {
            $cmdbItem = GetCmdbItemObject $_

            # If the item declares a dependency
            if ($null -ne $cmdbItem.DependsOn) {
                # Evaluate whether or not the dependency is applicable
                $itemData = $record
                foreach ($element in $cmdbItem.Name.Split('.')) { 
                    if ($itemData.PSObject.Properties.Item($element)) {
                        $itemData = $itemData.$element
                    }
                }

                # Attempt to follow the dependency
                if ($null -ne $itemData) {
                    foreach ($property in $cmdbItem.DependsOn.Keys) {
                        if ($null -ne $itemData.$property) {
                            $filter = '{0} -eq "{1}"' -f $cmdbItem.DependsOn[$property], $itemData.$property

                            Get-CmdbNode -Filter $filter | ForEach-Object {
                                Write-Host ('{0}Depends on {1}' -f (' ' * 4 * $level), $_.Node.Name) -ForegroundColor Cyan

                                Get-CmdbParentNode -NodeName $_.Node.Name -Level ($level + 1)
                            }
                        }
                    }
                }
            }
        }

        if ($record.Node.ChassisName) {
            Write-Host ('{0}Depends on chassis {1}' -f (' ' * 4 * $level), $record.Node.SiteName) -ForegroundColor Yellow
        }

        if ($record.Node.SiteName -and $record.Node.SiteName -ne 'Virtual') {
            Write-Host ('{0}Depends on site {1}' -f (' ' * 4 * $level), $record.Node.SiteName) -ForegroundColor Yellow
        }
    }
}