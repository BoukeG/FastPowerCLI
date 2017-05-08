#requires -version 4
<#
.SYNOPSIS
  Initial 'fast' script.

.DESCRIPTION
  This script gathers all data from the vCenters. Using get-view, it requests all required info. Grouping VMs by powerstate is
  done using group-object cmdlet. This is significantly faster then using if statements.

  This script uses the COTL method - Collect once, then loop.

.OUTPUTS
  $null

.NOTES
  Version:        1.0
  Author:         Bouke Groenescheij
  Creation Date:  2017-3-19
  Purpose/Change: Initial script development

.EXAMPLE
  In my environment it results in:
  TotalSeconds : 0,392774

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

#Gather all info from vCenter using get-view and the viewtype
$vmsview = get-view -ViewType "VirtualMachine" -Property "Runtime.PowerState"

#Start the stopwatch for timing (can be removed in production, not required for correct execution)
$sw = [Diagnostics.Stopwatch]::StartNew()

#Group-object by powerstate - this is very fast!
$groupedvmsview = $vmsview | Group-Object -Property {$_.Runtime.PowerState}

$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

Disconnect-VIServer * -Force -Confirm:$false