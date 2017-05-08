#requires -version 4
<#
.SYNOPSIS
  Extended 'fastest' script.

.DESCRIPTION
  This script gathers all data from the vCenters. Using get-view, it requests all required info, limited with the property option.
  Using where-object to relate the MoRef-ID to the child item MoRef-ID. Also, compare 'Client.ServiceUrl' to ensure multi-connected
  vCenter servers are resolved correct since MoRef is unique in vCenter, not across vCenters. The amount of properties are comparable
  with 'collect.fast.3.ps1'. So you can compare the performance/output with collect-fast.3.ps1.

  Major change is using hashtables instead of where-object.

  This script uses the COTL method - Collect once, then loop.

.OUTPUTS
  results-fast.4.csv

.NOTES
  Version:        1.0
  Author:         Bouke Groenescheij
  Creation Date:  2017-3-19
  Purpose/Change: Initial script development

.EXAMPLE
  In my environment it results in:
  TotalSeconds : 1,1115454

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
$vmsview = get-view -ViewType "VirtualMachine" -Property "Name","Datastore","Runtime.Host"
$computesview = get-view -ViewType "ComputeResource" -Property "Name","ConfigurationEx"
$hostsview = get-view -viewtype "HostSystem" -Property "Name","Parent","Runtime.PowerState","Hardware.SystemInfo.Model"
$datastoreview = get-view -viewtype "Datastore" -Property "Name","Info"

#Create the hashtables
$vmsviewhash = @{}
$computesviewhash = @{}
$hostsviewhash = @{}
$datastoreviewhash = @{}

#Fill the hashtables
$vmsview | ForEach-Object {$vmsviewhash.Add($_.Client.ServiceUrl+$_.Moref,$_)}
$computesview | ForEach-Object {$computesviewhash.Add($_.Client.ServiceUrl+$_.Moref,$_)}
$hostsview | ForEach-Object {$hostsviewhash.Add($_.Client.ServiceUrl+$_.Moref,$_)}
$datastoreview | ForEach-Object {$datastoreviewhash.Add($_.Client.ServiceUrl+$_.Moref,$_)}

#Create an array for the results
$results = @()

#Run through all VMs to gather the info
foreach ($vmview in $vmsview) {

    #Create an object with the properties
    $row = "" | Select-Object "Name","Cluster","HAEnabled","DRSEnabled","ESX Host","PowerState","Model","Datastore","FreeSpaceGB","FileSystemVersion"
    
    #Fill the properties. To find the relation between the correct MoRef Id, we use hashtables.
    $row.Name = $vmview.Name

    $hostobj = $hostsviewhash.$($vmview.Client.ServiceUrl+$vmview.Runtime.Host)
    $row."ESX Host" = $hostobj.Name
    $row."PowerState" = $hostobj.Runtime.PowerState
    $row."Model" = $hostobj.Hardware.SystemInfo.Model

    $hostparentobj = $computesviewhash.$($hostobj.Client.ServiceUrl+$hostobj.Parent)
    if ($hostparentobj -is [VMware.Vim.ClusterComputeResource]) {
        $row.Cluster = $hostparentobj.Name
        $row.HAEnabled = $hostparentobj.ConfigurationEx.DasConfig.Enabled
        $row.DRSEnabled = $hostparentobj.ConfigurationEx.DrsConfig.Enabled
    } else {
        $row.Cluster = $null
        $row.HAEnabled = $null
        $row.DRSEnabled = $null
    }

    $datastores = @()
    $datastoresfree = @()
    $datastoresversion = @()
    foreach ($ds in $vmview.Datastore) {
        $dsview = $datastoreviewhash.$($vmview.Client.ServiceUrl+$ds)
        $datastores += $dsview.name
        $datastoresfree += $dsview.Info.FreeSpace / 1Gb
        $datastoresversion += $dsview.Info.Vmfs.Version
    }
        
    $row.Datastore = $datastores -join ";"
    $row.FreeSpaceGB = $datastoresfree -join ";"
    $row.FileSystemVersion = $datastoresversion -join ";"

    #Add the properties to the object
    $results += $row
}

#Export the results to file
$results | Export-Csv -NoTypeInformation results-fast.4.csv

#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

#Disconnect from all vCenter servers
Disconnect-VIServer * -Force -Confirm:$false