param($vcenter,$session,$esxhost)
Write-Host "Info - Script starts with arguments: vcenter:$($vcenter), esxhost:$($esxhost)"

if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue
}

connect-viserver $vcenter -session $session -WarningAction:Ignore -ErrorAction:Stop | out-null

try {
    Write-Host "Info - Rescanning host: $($esxhost)"
	$esxhostview = Get-View -ViewType "hostsystem" -Property "ConfigManager.StorageSystem" -Filter @{"Name" = "^" + $esxhost + "$"}
	$cmss = get-view $esxhostview.ConfigManager.StorageSystem -Property "availableField"
	$cmss.RescanAllHba()
}
catch {
	Write-Host "Info - Something went wrong while rescanning host: $($esxhost)"
}
Write-Host "Info - Script ended with arguments: vcenter:$($vcenter), esxhost:$($esxhost)"