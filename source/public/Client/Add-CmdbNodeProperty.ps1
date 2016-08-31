function Add-CmdbNodeProperty {
    # .SYNOPSIS
    #   Add a property to the Node element of the document.
    # .DESCRIPTION
    #   Each record in the database consists of a document which contains a number of sub-documents.
    #   For example, Node is a sub-document of the record.
    #
    #   This command supports changes to the node sub-document by requesting the record, merging changes 
    #   and writing the record back.
    # .PARAMETER Filter
    # .PARAMETER Properties
    #   A hashtable holding each of the properties to be merged into the node sub-document.
    # .INPUTS
    #   System.Hashtable
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     19/08/2016 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Filter,

        [Parameter(Mandatory = $true)]
        [Hashtable]$Properties
    )

    if ($Filter.IndexOf(' ') -eq -1) {
        # Assume Filter is a node name and use it.
        $Filter = 'Node.Name -eq "{0}"' -f $Filter.ToLower()
    }
    try {
        $Filter = ConvertToMongoDBFilter $Filter -ErrorAction Stop | ConvertTo-Json -Compress -Depth 10
        $Script:mongoDBConnection.FindDocument($Filter) | ConvertFrom-Json | ForEach-Object {
            $node = $_.Node
            foreach ($property in $Properties.Keys) {
                $node | Add-Member $property $Properties[$property] -Force
            }
            Set-CmdbNode -Filter $node.Name -Document $node -Item Node
        }
    } catch {
        Write-Error -ErrorRecord $_
    }
}