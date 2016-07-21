function Get-CmdbMessageQueue {
    # .SYNOPSIS
    #   Get the items in the processing queue used by the CMDB to harvest information.
    # .DESCRIPTION
    #   Get-CmdbMessageQueue allows an administrator to view the items in each of the message bus queues when the queue is resident in memory.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    # 
    #   Change log:
    #     04/07/2016 - Chris Dent - Created.

    if ($Script:settings.MessageBusMode -eq 'Memory') {
        return $Script:queue
    }
}