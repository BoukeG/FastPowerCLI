#requires -version 4
<#
.SYNOPSIS
  Initial script.

.DESCRIPTION
  This script connects to vCenter, grabs all hosts. A job scriptblock is defined and called for each host. This allows
  parallel execution. 

.OUTPUTS
  $null

.NOTES
  Version:        1.0
  Author:         Bouke Groenescheij
  Creation Date:  2017-3-19
  Purpose/Change: Initial script development

.EXAMPLE
  Name                           Port  User
  ----                           ----  ----
  lab1vc                         443   VSPHERE.LOCAL\readwrite
  lab2vc                         443   VSPHERE.LOCAL\readwrite
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Some rescan jobs are still running
  Info - Rescanning host: esx2.fritz.box
  Info - Rescanning host: esx3.fritz.box
  Some rescan jobs are still running
  Info - Rescanning host: esx4.fritz.box
  Some rescan jobs are still running
  Info - Script ended with arguments: vcenter:lab1vc, esxhost:esx2.fritz.box
  Info - Script ended with arguments: vcenter:lab2vc, esxhost:esx3.fritz.box
  Some rescan jobs are still running
  Info - Script ended with arguments: vcenter:lab2vc, esxhost:esx4.fritz.box
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
$user = "readwrite@vsphere.local"

#This is the full job, note a job runs in it's own memory space - so you need to load the powercli modules
$rescanjob = {
	if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {
   		Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue
	}

	#Connect to the vCenter server - no need to login again, just use the same session
	connect-viserver $args[0] -session $args[1] -WarningAction:Ignore -ErrorAction:Stop | out-null

	#Run the actual rescan
	try {
		Write-Host "Info - Rescanning host: $($args[2])"

		#Filter on a single host, grabbed from the arguments
		$esxhostview = Get-View -ViewType "hostsystem" -Property "ConfigManager.StorageSystem" -Filter @{"Name" = "^" + $args[2] + "$"}
		$cmss = get-view $esxhostview.ConfigManager.StorageSystem -Property "availableField"
		$cmss.RescanAllHba()
	}
	catch {
		Write-Host "Info - Something went wrong while rescanning host: $($args[2])"
	}
	Write-Host "Info - Script ended with arguments: vcenter:$($args[0]), esxhost:$($args[2])"
}
#This is the end of the scriptblock

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Connect to all vCenter servers, create your credential store first
foreach ($vcenter in $vcenters) {
    $cred = Get-VICredentialStoreItem -Host $vcenter -User $user
    Connect-VIServer $cred.Host -User $cred.User -Password $cred.Password
}

#Get all hosts, you only need one property (like name), also you can use a filter
$HostsView = Get-View -ViewType "hostsystem" -Property "name"

#Run through all hosts
foreach ($HostView in $HostsView) {

	#Define the variables and pass them as arguments. Note the session variable, this enables fast login.
	$vcenter = ($HostView.Client.ServiceUrl).split("/")[2]
	$session = $HostView.Client.SessionSecret
	$esxhost = $HostView.Name

	#Start the job
	start-job -argumentlist $vcenter,$session,$esxhost -scriptblock $rescanjob | out-null
}

#Monitor the job
$somejobsrunning = $true
do {
  Write-Host "Some rescan jobs are still running"
	$jobs = Get-Job
	$jobs | Receive-Job
	$groupedjobs = $jobs | Group-Object "State"
	if ($groupedjobs.Values.Count -eq 1 -and $groupedjobs.Name -eq "Completed") { $somejobsrunning = $false }
	Start-Sleep 1
}
while ($somejobsrunning)
Get-Job | Receive-Job
Get-Job | Remove-Job

#Disconnect from all vCenter servers - don't do this in the scriptblock - it will invalidate your sessionkey.
Disconnect-VIServer * -Force -Confirm:$false