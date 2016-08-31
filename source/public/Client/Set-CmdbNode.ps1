function Set-CmdbNode {
    # .SYNOPSIS
    #   Set data values on a CMDB node.
    # .DESCRIPTION
    #
    # .PARAMETER Filter
    #   The name of an existing CMDB node.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     17/08/2016 - Chris Dent - Refactored.

    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$Filter,

        [Parameter(Mandatory = $true, Position = 2)]
        [PSObject]$Document,

        [String]$Item
    )

    if ($Filter.IndexOf(' ') -eq -1) {
        # Assume Filter is a node name and use it.
        $Filter = 'Node.Name -eq "{0}"' -f $Filter.ToLower()
    }

    if ($psboundparameters.ContainsKey('Item')) {
        # Re-order items subject to either a resolved item name or a literal item name
        $cmdbItem = Get-CmdbItem $Item -ErrorAction SilentlyContinue
        if ($null -ne $cmdbItem) {
            $Item = $cmdbItem.Name
        }

        [Array]$elements = $Item.Split('.')
        for ($i = $elements.Count - 1; $i -ge 0; $i--) {
            $Document = [PSCustomObject]@{
                ($elements[$i]) = $Document
            }
        }
    }

    # This still needs to retrieve which is a bit of a shame because Filter is broad at this point
    try {
        $Filter = ConvertToMongoDBFilter $Filter | ConvertTo-Json -Depth 10
        # If nothing matches the filter this will be treated as an upsert rather than a sub-document modification
        $hasUpdated = $false

        # Nested document handler. If an item hasn't been supplied nested documents may be overwritten.
        if ($psboundparameters.ContainsKey('Item') -and $Item -ne 'Node' -and $Item.IndexOf('.') -gt -1) {
            $destination = $Document
            $elements = $Item.Substring(0, $Item.LastIndexOf('.')).Split('.')

            $Script:mongoDBConnection.FindDocument($Filter) | ConvertFrom-Json | ForEach-Object {
                Write-Debug -Message ('Updating sub-document for record with id {0} ({1})' -f $_._id.'$oid', $_.Node.Name)

                $hasUpdated = $true
                $source = $_

                # Merge the documents
                foreach ($element in $elements) {
                    $source = $source.$element
                    $destination = $destination.$element
                }
                foreach ($property in $source.PSObject.Properties) {
					if (-not $destination.PSObject.Properties.Item($property.Name)) {
                        $destination | Add-Member $property.Name $property.Value
                    }
                }

                # Update this document only
                $update = [PSCustomObject]@{
                    '$set' = $Document
                }

                $Script:mongoDBConnection.UpdateDocument(
                    ('{{ "_id": {{ "$oid": "{0}" }} }}' -f $_._id.'$oid'),
                    ($update | ConvertTo-Json -Depth $Script:settings.JsonDepth),
                    $true
                )
            }
        }
        if ($hasUpdated -eq $false) {
            Write-Debug -Message 'Upserting record'

            $update = [PSCustomObject]@{
                '$set' = $Document
            }
            $Script:mongoDBConnection.UpdateDocument(
                $Filter,
                ($update | ConvertTo-Json -Depth $Script:settings.JsonDepth),
                $true
            )
        }
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    }
}