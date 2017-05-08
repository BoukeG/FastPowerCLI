#requires -version 4
<#
.SYNOPSIS
  Initial 'slow' script.

.DESCRIPTION
  This script gathers all data from the vCenters. Using get-view, it requests all required info. Grouping VMs by powerstate is
  done using if statements. This is significantly slower then using group-object cmdlet.

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
  TotalSeconds : 10,3649351

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
$sw1 = [Diagnostics.Stopwatch]::StartNew()

#define some arrays to put the data in
$poweredOn = @()
$poweredOff = @()
$unknown = @()
foreach ($vmview in $vmsview) {
    if ($vmview.Runtime.PowerState -eq "poweredOn") {
        $poweredOn += $vmview
    } elseif ($vmview.Runtime.PowerState -eq "poweredOff") {
        $poweredOff += $vmview
    } else {
        $unknown += $vmview
    }
}

#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw1.Stop()
$sw1.Elapsed | select-object TotalSeconds

#Disconnect from all vCenter servers
Disconnect-VIServer * -Force -Confirm:$false