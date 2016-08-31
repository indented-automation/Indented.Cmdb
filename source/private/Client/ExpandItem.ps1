function ExpandItem {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$InputObject,

        [AllowNull()]
        [String]$Name
    )

    process {
        if ($Name -eq [String]::Empty) {
            return $InputObject
        }
        
        foreach ($element in $Name.Split('.')) {
            $InputObject = $InputObject.$element
        }
        return $InputObject
    }
}