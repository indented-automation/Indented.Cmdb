function ConvertExpression {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Convert collection of statements with a common logic operator into a single PSObject representation of a MongoDB filter.
    # .PARAMETER Filter
    #   The filter to convert.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     17/08/2016 - Chris Dent - Bug fix: Logic reversal for match / cmatch.
    #     11/08/2016 - Chris Dent - Bug fix: And / Or statement construction. Match options.
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
    
    $isLeftOfOperator = $true
    [Array]$expressions = for ($i = 0; $i -lt $tokens.Count; $i++) {
        $token = $tokens[$i]

        if ($isLeftOfOperator) {
            switch ($token.Kind) {
                { $_ -eq 'Generic' -and $token.Text -eq 'eof>' } { break }
                { $_ -eq 'Parameter' -and $token.ParameterName -in 'And', 'Or' } { break }
                { $_ -in 'Generic', 'Identifier' } {
                    $propertyName = $token.Text
                    $working = $expression = [PSCustomObject]@{
                        $propertyName = New-Object PSObject
                    }
                    break
                }
                'Parameter' {
                    $isLeftOfOperator = $false

                    switch ($token.ParameterName) {
                        'eq'    { break }
                        'notin' { $_ = 'nin' }
                        'ge'    { $_ = 'gte' }
                        'le'    { $_ = 'lte' }
                        { $_ -in 'match', 'cmatch' } {
                            $operatorName = '$regex'
                            $options = ''
                            if ($_ -eq 'match') { $options = 'i' }

                            $working.$propertyName | Add-Member '$regex' $null
                            $working.$propertyName | Add-Member '$options' $options
                            $working = $working.$propertyName
                            $propertyName = $operatorName
                            break
                        }
                        { $_ -in 'exists', 'gt', 'gte', 'in', 'lt', 'lte', 'ne', 'nin' } {
                            $operatorName = '${0}' -f $_
                            $working.$propertyName | Add-Member $operatorName $null
                            $working = $working.$propertyName
                            $propertyName = $operatorName
                            break
                        }
                        default {
                            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                                (New-Object ArgumentException ('The requested operator ({0}) is not supported' -f $token.ParameterName)),
                                'OperatorNotSupported,ConvertExpression',
                                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                                $Filter
                            )
                            throw $errorRecord
                        }
                    }
                    break
                }
            }
        } else {
            $shouldSet = $false
            if ($token.Kind -in 'Generic', 'Identifier', 'Variable') {
                if ($token.Kind -in 'Generic', 'Identifier') {
                    $name = $token.Text
                } else {
                    $name = $token.Name
                }
                if (Test-Path ('Variable:\{0}' -f $name)) {
                    $value = (Get-Variable $name).Value
                    $shouldSet = $true
                } else {
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                        (New-Object ArgumentException ('The requested variable {0} is not available' -f $token.Text)),
                        'VariableNotDeclared,ConvertExpression',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Filter
                    )
                    throw $errorRecord
                }
            } elseif ($token.Kind -in 'Number', 'StringExpandable', 'StringLiteral') {
                $value = $token.Value
                $shouldSet = $true
            }

            if ($shouldSet) {
                if ($null -eq $working.$propertyName -or $working.$propertyName -is [PSObject]) {
                    $working.$propertyName = $value
                } else {
                    $working.$propertyname = @($working.$propertyName) + @($value)
                }
                if ($i -ge $tokens.Count -or $tokens[$i + 1].Kind -ne 'Comma') {
                    # Return the parsed expression
                    $expression
                    $isLeftOfOperator = $true
                }
            }
        }
    }

    $logicOperator = GetLogicOperator $Filter
    if ($expressions.Count -eq 1) {
        return $expressions
    } elseif ($logicOperator -and $expressions.Count -gt 1) {
        return [PSCustomObject]@{
            $logicOperator = $expressions
        }
    } else {
        $errorRecord = @{
            Exception = New-Object InvalidOperationException 'Unexpected error'
            Category  = 'InvalidArgument'
            ErrorId   = 'FilterParseFailed'
        }
        Write-Error @errorRecord
    }
}