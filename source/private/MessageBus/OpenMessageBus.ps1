function OpenMessageBus {
    # .SYNOPSIS
    #   Internal use only.
    # .DESCRIPTION
    #   Each of the commands operates around the notion of an abstract queue.
    #
    #   The commands to acquire information from raw sources do not interact directly, each 
    #   operates on a queue. 
    #
    #   The following queues are defined:
    #
    #     * Update queue  - Updates existing items. Queue (FIFO).
    #     * Import queue  - Imports and adds new items. Queue (FIFO).
    #     * GetData queue - A data processing stack. Queue (FIFO).
    #     * SetData queue - A data processing stack. Queue (FIFO).
    #
    #   All queues must only contain JSON formatted data.
    #
    #   Three different queue types may be initialised by this command depending on the settings:
    #
    #     * Folder     - The set of queues is stored in a folder and accessible from all nodes with access to that folder.
    #     * RabbitMQ   - RabbitMQ is used to host the queue and is accessible from all nodes able to access RabbitMQ.
    #     * Standalone - The set of queues is stored in memory and accessible from the current PowerShell session only.
    #
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     05/07/2016 - Chris Dent - Created.

    NewQueue -Name 'Update', 'Import', 'GetData', 'SetData', 'Failed'
}