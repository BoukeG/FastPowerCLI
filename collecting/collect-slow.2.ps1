#requires -version 4
<#
.SYNOPSIS
  Extended 'slow' script.

.DESCRIPTION
  This oneliner gathers all VMs from the vCenters. Through piping it is passed to get-cluster, get-vmhost and get-datastore.
  Then this is put into .csv. The command execution is quite slow, since every VM, Cluster, Host and Datastore is requested
  multiple times. Compared to the 'collect-slow.1.ps1' this script gather multiple details from one source.

  This script is used as an example taken from:
  https://ict-freak.nl/2009/11/17/powercli-one-liner-to-get-vms-clusters-esx-hosts-and-datastores/
  
  Some modifications are made to this code. Mainly to increase execution time for demo purposes.

.OUTPUTS
  results-slow.2.csv

.NOTES
  Version:        1.0
  Author:         Bouke Groenescheij (original concept Arne Fokkema - ICT-Freak)
  Creation Date:  2017-3-19
  Purpose/Change: Initial script development

.EXAMPLE
  In my environment it results in:
  TotalSeconds : 436,1601444

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

#Collect the info and export to csv. Output is available in 'results-slow.1.csv'
Get-VM | Select-Object Name, `
                       @{N="Cluster";E={(Get-Cluster -VM $_ | Select-Object "Name").Name}}, `
                       @{N="HAEnabled";E={(Get-Cluster -VM $_ | Select-Object "HAEnabled").HAEnabled}}, `
                       @{N="DRSEnabled";E={(Get-Cluster -VM $_ | Select-Object "DRSEnabled").DRSEnabled}}, `
                       @{N="ESX Host";E={(Get-VMHost -VM $_ | Select-Object "Name").Name}}, `
                       @{N="PowerState";E={(Get-VMHost -VM $_ | Select-Object "PowerState").PowerState}}, `
                       @{N="Model";E={(Get-VMHost -VM $_ | Select-Object "Model").Model}}, `
                       @{N="Datastore";E={(Get-Datastore -VM $_ | Select-Object "Name").Name}}, `
                       @{N="FreeSpaceGB";E={(Get-Datastore -VM $_ | Select-Object "FreeSpaceGB").FreeSpaceGB}}, `
                       @{N="FileSystemVersion";E={(Get-Datastore -VM $_ | Select-Object "FileSystemVersion").FileSystemVersion}} | `
                       Export-Csv -NoTypeInformation results-slow.2.csv

#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

#Disconnect from all vCenter servers
Disconnect-VIServer * -Force -Confirm:$false