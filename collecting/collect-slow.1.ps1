#requires -version 4
<#
.SYNOPSIS
  Initial 'slow' script.

.DESCRIPTION
  This oneliner gathers all VMs from the vCenters. Through piping it is passed to get-cluster, get-vmhost and get-datastore.
  Then this is put into .csv. The command execution is quite slow, since every VM, Cluster, Host and Datastore is requested
  multiple times.

  This script is used as an example taken from:
  https://ict-freak.nl/2009/11/17/powercli-one-liner-to-get-vms-clusters-esx-hosts-and-datastores/
  
  No significant changes has been made to this code.

.OUTPUTS
  results-slow.1.csv

.NOTES
  Version:        1.0
  Author:         Bouke Groenescheij (original concept Arne Fokkema - ICT-Freak)
  Creation Date:  2017-3-19
  Purpose/Change: Initial script development

.EXAMPLE
  In my environment it results in:
  TotalSeconds : 152,1580453

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
                       @{N="Cluster";E={Get-Cluster -VM $_}}, `
                       @{N="ESX Host";E={Get-VMHost -VM $_}}, `
                       @{N="Datastore";E={Get-Datastore -VM $_}} | `
                       Export-Csv -NoTypeInformation results-slow.1.csv

#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

#Disconnect from all vCenter servers
Disconnect-VIServer * -Force -Confirm:$false