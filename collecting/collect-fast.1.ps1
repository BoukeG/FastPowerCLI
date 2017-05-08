#requires -version 4
<#
.SYNOPSIS
  Initial 'fast' script.

.DESCRIPTION
  This script gathers all data from the vCenters. Using get-view, it requests all required info. Using where-object to relate the
  MoRef-ID to the child item MoRef-ID. Also, compare 'Client.ServiceUrl' to ensure multi-connected vCenter servers are resolved
  correct since MoRef is unique in vCenter, not across vCenters. The amount of properties are comparable with 'collect.slow.1.ps1'.
  So you can compare the performance/output with collect-slow.1.ps1.

  No significant changes has been made to this code.

  This script uses the COTL method - Collect once, then loop.

.OUTPUTS
  results-fast.1.csv

.NOTES
  Version:        1.0
  Author:         Bouke Groenescheij
  Creation Date:  2017-3-19
  Purpose/Change: Initial script development

.EXAMPLE
  In my environment it results in:
  TotalSeconds : 7,0160254

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue
}

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$vcenters = @()
$vcenters += "lab1vc"
$vcenters += "lab2vc"
$user = "readonly@vsphere.local"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Connect to all vCenter servers, create your credential store first
foreach ($vcenter in $vcenters) {
    $cred = Get-VICredentialStoreItem -Host $vcenter -User $user
    Connect-VIServer $cred.Host -User $cred.User -Password $cred.Password
}

#Start the stopwatch for timing (can be removed in production, not required for correct execution)
$sw = [Diagnostics.Stopwatch]::StartNew()

#Gather all info from vCenter using get-view and the viewtype
$vmsview = get-view -ViewType "VirtualMachine"
$computesview = get-view -ViewType "ComputeResource"
$hostsview = get-view -viewtype "HostSystem"
$datastoreview = get-view -viewtype "Datastore"

#Create an array for the results-fast
$results = @()

#Run through all VMs to gather the info
foreach ($vmview in $vmsview) {

    #Create an object with the properties
    $row = "" | Select-Object "Name","Cluster","ESX Host","Datastore"

    #Fill the properties. To find the relation between the correct MoRef Id, we use where-object to compare the MoRef ID AND the Client.ServiceURL
    $row.Name = $vmview.Name

    $hostobj = $hostsview | Where-Object {$_.MoRef -eq $vmview.Runtime.Host -and $_.Client.ServiceUrl -eq $vmview.Client.ServiceUrl}
    $row."ESX Host" = $hostobj.Name

    $hostparentobj = $computesview | where-object {$_.Moref -eq $hostobj.Parent -and $_.Client.ServiceUrl -eq $vmview.Client.ServiceUrl}
    if ($hostparentobj -is [VMware.Vim.ClusterComputeResource]) {
        $row.Cluster = $hostparentobj.name
    } else {
        $row.Cluster = $null
    }

    $datastores = @()
    foreach ($ds in $vmview.Datastore) {
        $datastores += ($datastoreview | where-object {$_.moref -eq $ds -and $_.Client.ServiceUrl -eq $vmview.Client.ServiceUrl}).name
    }
    $row.Datastore = $datastores -join ","

    #Add the properties to the object
    $results += $row
}

#Export the results to file
$results | Export-Csv -NoTypeInformation results-fast.1.csv

#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

#Disconnect from all vCenter servers
Disconnect-VIServer * -Force -Confirm:$false