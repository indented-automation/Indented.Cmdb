#
# Indented.CMDB
#
# Author: Chris Dent
#
# Change log:
#   15/06/2016 - Chris Dent - Created

'Public', 'Internal' | ForEach-Object {
    Get-ChildItem "$psscriptroot\$_" -Filter *.ps1 -Recurse | ForEach-Object {
        . $_.FullName
    }
}

InitializeModule