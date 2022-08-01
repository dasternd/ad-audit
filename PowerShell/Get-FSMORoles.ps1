Write-Host Forest Mode
$ADForest = Get-ADForest
$forestMode = $ADForest.ForestMode
$forestMode


Write-Host
Write-Host FSMO roles

# FSMO roles
Write-Host
Write-Host PDSEmulator
$PDCEmulator = $ADDomain.PDCEmulator
$PDCEmulator

Write-Host
Write-Host InfrastructureMaster
$InfrastructureMaster = $ADDomain.InfrastructureMaster
$InfrastructureMaster

Write-Host
Write-Host RIDMaster
$RIDMaster = $ADDomain.RIDMaster
$RIDMaster

Write-Host
Write-Host DomainNamingMaster
$DomainNamingMaster = $ADForest.DomainNamingMaster
$DomainNamingMaster

Write-Host
Write-Host SchemaMaster
$SchemaMaster = $ADForest.SchemaMaster
$SchemaMaster 
