#
#  This script prerequisite for audit AD
#  Author: Danil Stepanov, msware.ru (c) 2022
#

# адрес каталога проекта, где будет размещены все входные и выходные файлы
$pathProject = Get-Location 
$pathProject = $pathProject.Path + "\"
# адрес размещения лог-файла
$pathLogFile = $pathProject + "Prerequisite-" + (Get-Date).ToString('yyyy_MM_dd_HH_mm') + ".log" 

# ФУНКЦИЯ ЛОГИРОВАНИЯ СОБЫТИЙ
function WriteLog
{
    Param ([string]$LogString)
    $LogFile = $pathLogFile
    $DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"
    Add-content $LogFile -value $LogMessage
}

Write-Host "Prerequisite for audit Active Directory"

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
WriteLog "List Domain Controllers"
$domControllers = Get-ADDomainController -filter * | Select-Object HostName
$totalDC = $domControllers.Count
for ($i = 0; $i -lt $domControllers.Count; $i++) {
    WriteLog $domController.HostName PS version $PSVer.PSVersion
    $domControllers[$i].HostName
} 
WriteLog "[Info] Total Domain Controllers $totalDC"

WriteLog "Version PowerShell"
foreach ($domController in $domControllers) {
    $PSVer = Invoke-Command -ComputerName $domController.HostName -ScriptBlock { $PSVersionTable }
    try {
        Write-Host
        WriteLog $domController.HostName PS version $PSVer.PSVersion
        Write-Host $domController.HostName PS version $PSVer.PSVersion 
    }
    catch {
        Write-Host
        Write-Host $Error
        WriteLog $Error
    }
} 