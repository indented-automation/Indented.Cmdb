# Indented.CMDB

Documentation for Indented.Cmdb is a bit light, so until it is wired up.

## Goal

To create a light-weight, low footprint tool which supports highly customisable agent-less information gathering from widely distributed servers.

The tool must allow data to be drawn in quickly and must provide a reasonable query interface.

## Settings

## Items

A record can be said to be the everything the database knows about a single node or server. The record consists of one or more Items. For example, the details of the Processors on a node is considered to be an item. In MongoDB an item is a sub-document.

A record will always include a Node item, this holds the Name property which may be treated as the unique identifier for a record.

The instructions for gathering data from an item constructed from a name and hashtable as in the following template.

```powershell
CmdbItem SomeItem @{
    # If the query requires snap-ins, such as a query for VMWare.VimAutomation.Core these 
    # can be cleanly added to the initial session state. This will eventually be used to assess poller
    # feasibility. For example:
    #   ImportPSSnapIn = 'VMWare.VimAutomation.Core'
    ImportPSSnapIn = 'SomeSnapIn'

    # Properties may be an array. If omitted all properties on the object returned by Get or Import 
    # are pushed into the database.
    Properties = @(
        Property1
        Property2
    )

    # CopyToNode may be used to extend the properties held in the Node item. Properties declared 
    # here are automatically copied from the resultant object.
    CopyToNode = @(
        Property1
    )

    # The Get script block describes how to acquire the item record for a single node. The 
    # following variables are made avaialble to Get:
    #   * Node - The content of the Node item.
    #   * Item - The result or executing this.
    Get = {
        Get-Something -Target $Node.Name -Properties $Item.Properties 
    }

    # The Import script block describes how multiple nodes should be drawn in. The following 
    # variables are made available to Import:
    #   * Item - The result or executing this.
    Import = {
        Get-Something -Properties $Item.Properties
    }

    # Import match may be a string or script block. It should result in a value which can be mapped
    # to Node.Name. For example, if a property called "Name" contained "name.domain.com" then ImportMatch 
    # as a script block might strip .domain.com.
    ImportMatch = 'SomeProperty'
}
```

## Message bus

The message bus provides an independent means of communication between different components.

The message bus is limited to providing communication between client and poller(s). Requests to Import or Update data are dropped into the message queue and picked up by any interested pollers.

The data service is deprecated at present until it gains another job. Accessing the database through the message queue provides no benefit at this time. 

It is expected that there will be more than one poller to spread the work of drawning information in. I intend to add features to support specialised pollers (based on rules or based on module / snap-in availability).

## Data service

The data service does nothing at the moment. It provided a front-end to file-backed data stores and may again if I reintroduce that feature. It exists to allow as much data reading and filtering to happen on the server side such that a client does not need to download the entire database when executing a query against a bunch of files. 

The data service may grow into a broker, expanding summarised requests from clients. That is, a client should not have a enqueue x requests for an item where x is the total number of devices in the database. The data service may pick up a request then expand it to allow distribution. 

## Poller

The poller is based around a buffered runspace pool. A poller will pick up item requests from the message bus and enqueue each under its runspace pool. The runspace pool executes a configurable number of threads with a configurable total "queue" size (executing plus queued).

Requests for the poller to act are added via the client. The poller itself is intended to be a passive always-on service and will eventually be wrapped into a windows service.

## Client

### Add-CmdbNodeProperty

Modification of an item in a record can be considered to be a specialized operation. The existing item must be extracted, changes merged and the modified item added again.

Add-CmdbNodeProperty allows modification of the Node item via a hashtable.

```powershell
Add-CmdbNodeProperty -Filter "VirtualInfrastructure.Guest -exists $true" -Properties @{SiteName = 'Virtual'}
```

### Get-CmdbNode

*Note: When the data store is MongoDB all queries are case sensitive. This limitation applies to both the left and right hand side of an expression.*

Get-CmdbNode is the query tool. In it's simplest form it returns a record for a single node.

```powershell
Get-CmdbNode SomeComputerName
```

A filter is automatically constructed based on the name passed, this command is equivalent.

```powershell
Get-CmdbNode -Filter "Node.Name -eq 'somecomputername'" 
```

Filters support multiple terms with the `-and` or `-or` operators. For example:

```powershell
Get-CmdbNode -Filter "ActiveDirectory.ServicePrincipalName -eq 'HTTP\server1' -and ActiveDirectory.Enabled -eq $true"
```

If the Item parameter is declared the data for that item will be returned rather than the entire document.

```powershell
Get-CmdbNode -Filter "Network.Interface.MacAddress -eq 'AA:BB:CC:DD:EE:FF'" -Item Node
```

The Item parameter may be used to drill down into the individual properties.

```powershell
Get-CmdbNode -Filter "Network.Interface.MacAddress -eq 'AA:BB:CC:DD:EE:FF'" -Item Network.Interface.IPAddress
```

### Import-CmdbNode

An import request is expected to pull from a larger source such as Active Directory, or vCenter. In these cases it is often efficient to pull data in rather than attempt to execute a per-server query.

```powershell
Import-CmdbNode -Item ActiveDirectory
```

### Remove-CmdbNode

Completely removes a record from the database. At some point this will allow removal of specific items from a record.

### Set-CmdbNode

Adds new nodes as well as update existing nodes. For example, the following static data may be added to all nodes matching the filter.

```powershell
$Document = [PSCustomObject]@{
    SubnetName = 'Data centre'
    Size       = '24 bit'
}
Set-CmdbNode -Filter "Network.Interface.IPAddress -match '10\.0\.0\..*'" -Document $Document -Item Network.Subnet
```

### Update-CmdbNode

Update requests are generally expected to be based on information which is widely distributed such as WMI queries or other information which is specific to a single server.

```powershell
Update-CmdbNode -Name SomeExistingNode -Item Network.Interface
```


