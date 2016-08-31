function Remove-CmdbNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Filter,

        [String]$Item
    )

    # Remove all or part of a CMDB node
    if ($Filter.IndexOf(' ') -eq -1) {
        # Assume Filter is a node name and use it.
        $Filter = 'Node.Name -eq "{0}"' -f $Filter
    }
    try {
        $Filter = ConvertToMongoDBFilter $Filter | ConvertTo-Json -Depth 10
        $Script:mongoDBConnection.RemoveDocument($Filter)
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    }
}