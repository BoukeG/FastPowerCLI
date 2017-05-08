#requires -version 4
<#
.SYNOPSIS
  Initial script.

.DESCRIPTION
  This script gathers all data from the vCenters. Using get-view, it requests all required info.
  You can filter by object type to select the correct object. In this example we select a network adapter. Also works great
  with inheritance.

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
  Found 24165 mac addresses
  TotalSeconds : 9,9203526

  Found 24423 mac addresses
  TotalSeconds : 10,4524806

  Found 24423 mac addresses
  TotalSeconds : 9,9497114

  Conclusion is there is no performance difference - however, the last method is best.
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
$thevmsview = get-view -ViewType "VirtualMachine" -Property "Config.Hardware.Device"

#Start the stopwatch for timing (can be removed in production, not required for correct execution)
$sw = [Diagnostics.Stopwatch]::StartNew()
#Here we make an assumption (is bad) that all networkinterfaces are based on Vmxnet3.
$allmacs = ($thevmsview.Config.Hardware.Device | Where-Object {$_ -is [VMware.Vim.VirtualVmxnet3]}).MacAddress
write-host "Found $($allmacs.count) mac addresses"
#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

#Start the stopwatch for timing (can be removed in production, not required for correct execution)
$sw = [Diagnostics.Stopwatch]::StartNew()
#We can define all 'networktypes', however, this requires extra maintenance.
$allmacs = ($thevmsview.Config.Hardware.Device | Where-Object {$_ -is [VMware.Vim.VirtualE1000] -or $_ -is [VMware.Vim.VirtualE1000e] -or $_ -is [VMware.Vim.VirtualPCNet32] -or $_ -is [VMware.Vim.VirtualSriovEthernetCard] -or $_ -is [VMware.Vim.VirtualVmxnet]}).MacAddress
write-host "Found $($allmacs.count) mac addresses"
#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

#Start the stopwatch for timing (can be removed in production, not required for correct execution)
$sw = [Diagnostics.Stopwatch]::StartNew()
#The best way to handle this is using the parents type, which in this case is VirtualEthernetCard
$allmacs = ($thevmsview.Config.Hardware.Device | Where-Object {$_ -is [VMware.Vim.VirtualEthernetCard]}).MacAddress
write-host "Found $($allmacs.count) mac addresses"
#Stop the stopwatch for timing (can be removed in production, not required for correct execution)
$sw.Stop()
$sw.Elapsed | select-object TotalSeconds

#Disconnect from all vCenter servers
Disconnect-VIServer * -Force -Confirm:$false