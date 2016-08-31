function GetLogicOperator {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Attempt to establish the logic operator (if any) used in a script block. This is a best-effort search, the first operator which is not nested will be chosen.
    #
    #   Consider:
    #
    #     (Value1 -eq 1 -or Value2 -eq 2) -and Value3 -eq 3 -and Value4 -eq 4
    #
    #   This function will pick "and" from the statement and return '$and'.
    # .PARAMETER Filter
    #   The filter which should be searched.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.String
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     08/08/2016 - Chris Dent - Created.

    param(
        [String]$Filter
    )

    $tokens = $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
        $Filter,
        [Ref]$tokens,
        [Ref]$parseErrors
    )

    $logicOperator = ''
    # Find the first logic operator
    $isInGroup = $false
    foreach ($token in $tokens) {
        if ($token.Kind -eq 'LParen') {
            $isInGroup = $true
        }
        if ($token.Kind -eq 'RParen') {
            $isInGroup = $false
        }
        if (-not $isInGroup) {
            if (($token.Kind -eq 'Parameter' -and $token.Text -in '-and', '-or') -or ($token.Kind -in 'And', 'Or')) {
                $logicOperator = '${0}' -f ($token.Text -replace '^-')

                return $logicOperator
            }
        }
    }
    return $logicOperator
}