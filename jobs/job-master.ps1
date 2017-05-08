#requires -version 4
<#
.SYNOPSIS
  Initial script.

.DESCRIPTION
  This script connects to vCenter, grabs all hosts. A job scriptblock to execute an external script is defined and 
  called for each host. This allows parallel execution. 

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

#This is the job which calls another scripts, note a job runs in it's own memory space
$rescanjob = {
	$scriptPath = $args[0]
	set-location $scriptPath
	powershell -command "$($scriptPath)\job-slave.ps1 -vcenter $($args[1]) -session $($args[2]) -esxhost $($args[3])"
}
#This is the end of the scriptblock - since all of the work is in the other script, this script has a better overview

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Connect to all vCenter servers, create your credential store first
foreach ($vcenter in $vcenters) {
    $cred = Get-VICredentialStoreItem -Host $vcenter -User $user
    Connect-VIServer $cred.Host -User $cred.User -Password $cred.Password
}

#Get all hosts, you only need one property (like name), also you can use a filter
$HostsView = $esxhostview = Get-View -ViewType "hostsystem" -Property "name"

#Run through all hosts
foreach ($HostView in $HostsView) {

	#Define the variables and pass them as arguments. Note the session variable, this enables fast login.
	$vcenter = ($HostView.Client.ServiceUrl).split("/")[2]
	$session = $HostView.Client.SessionSecret
	$esxhost = $HostView.Name

	#The scriptPath variable is being used to determine the current location for the slave script in the scriptblock
	$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

	#Start the job (the argumentlist order is important, since the array index is used to read the values)
	start-job -argumentlist $scriptPath,$vcenter,$session,$esxhost -scriptblock $rescanjob | out-null
}

#Monitor the job
$somejobsrunning = $true
do {
	Write-Host "Some rescan jobs are still running"
	Get-Job | Receive-Job
	$jobs = Get-Job
	$groupedjobs = $jobs | Group-Object "State"
	if ($groupedjobs.Values.Count -eq 1 -and $groupedjobs.Name -eq "Completed") { $somejobsrunning = $false }
	Start-Sleep 1
}
while ($somejobsrunning)
Get-Job | Receive-Job
Get-Job | Remove-Job

#Disconnect from all vCenter servers - don't do this in the scriptblock - it will invalidate your sessionkey.
Disconnect-VIServer * -Force -Confirm:$false