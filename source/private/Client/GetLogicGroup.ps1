function GetLogicGroup {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Attempt to extract nested logic group from a larger expression.
    #
    #   For example, consider:
    #
    #     Value1 -eq 1 -and (Value2 -eq 2 -or Value3 -eq 3)
    #
    #   The nested statement will be extrated:
    #
    #     Value2 -eq 2 -or Value3 -eq 3
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     09/08/2016 - Chris Dent - Created.

    param(
        [String]$Filter
    )

    $tokens = $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
        $Filter,
        [Ref]$tokens,
        [Ref]$parseErrors
    )

    $defaultLogicOperator = GetLogicOperator $Filter

    $isInGroup = $false
    foreach ($token in $tokens) {
        if ($token.Kind -eq 'LParen') {
            if ($isInGroup) {
                # Die. Nested. Not supported.
            } else {
                $isInGroup = $true
                $group = [PSCustomObject]@{
                    Start         = $token.Extent.StartOffset
                    End           = $null
                    Filter        = $null
                    LogicOperator = ''
                }
            }
        }
        if ($token.Kind -eq 'RParen') {
            if ($isInGroup) {
                $group.End = $token.Extent.EndOffset
                $group.Filter = $Filter.Substring(
                    $group.Start,
                    $group.End - $group.Start
                ).Trim('()')
                $group.LogicOperator = GetLogicOperator $group.Filter
                $isInGroup = $false

                if ($group.LogicOperator -notin '', $defaultLogicOperator) {
                    $group
                }
            } else {
                # Die. Syntax error
            }
        }
    }
}