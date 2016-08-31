function ConvertToMongoDBFilter {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Attempts to convert a search filter written in near-PowerShell syntax to a PSObject representation of a filter for MongoDB.
    # .PARAMETER Filter
    #   A string containing a filter to be converted.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.String
    # .NOTES
    #   Author Chris Dent
    #
    #   Change log
    #     09082016 - Chris Dent - Created.
    
    param(
        [String]$Filter
    )

    $defaultLogicOperator = GetLogicOperator $Filter
    $groups = GetLogicGroup $Filter

    # Remove any nested expressions which implement their own logic from the main filter.
    foreach ($group in $groups) {
        $Filter = $Filter.Remove(
            $group.Start,
            $group.End - $group.Start
        )
    }

    $base = $working = ConvertExpression $Filter

    if ($defaultLogicOperator -ne '') {
        $working = $base.$defaultLogicOperator
    }
    
    # Add the extracted nested groups under the first logic operator. 
    foreach ($group in $groups) {
        $working | Add-Member $group.LogicOperator (ConvertExpression $group.Filter).($group.LogicOperator)
    }

    # Return the constructed filter as JSON
    $base
}