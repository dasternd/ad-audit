#
#  This script prerequisite for audit AD
#  Author: Danil Stepanov, msware.ru (c) 2022
#

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


Write-Host
Write-Host All Domain Controllers
$domControllers = Get-ADDomainController -filter * | Select-Object HostName 
for ($i = 0; $i -lt $domControllers.Count; $i++) {
    $domControllers[$i].HostName
} 

foreach ($domController in $domControllers) {
    $PSVer = Invoke-Command -ComputerName $domController.HostName -ScriptBlock { $PSVersionTable }
    Write-Host
    Write-Host $domController.HostName PS version $PSVer.PSVersion 
} 

 
