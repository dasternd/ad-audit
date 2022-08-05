#
#  This script prerequisite for audit AD
#  Author: Danil Stepanov, msware.ru (c) 2022
#

# адрес каталога проекта, где будет размещены все входные и выходные файлы
$pathProject = Get-Location 
$pathProject = $pathProject.Path + "\"
# адрес размещения лог-файла
$pathLogFile = $pathProject + "Prerequisite-" + (Get-Date).ToString('yyyy_MM_dd_HH_mm') + ".log" 
$doneError = $false

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

Write-Host
Write-Host All Domain Controllers
WriteLog "List Domain Controllers"
$domControllers = Get-ADDomainController -filter * | Select-Object HostName
$totalDC = $domControllers.Count

foreach ($domController in $domControllers) {
    WriteLog $domController.HostName
    Write-Host $domController.HostName
}
Write-Host Total Domain Controllers $totalDC
WriteLog "[Info] Total Domain Controllers $totalDC"

Write-Host
Write-Host Version PowerShell
WriteLog "Version PowerShell"
foreach ($domController in $domControllers) {
    try {
        $PSVer = Invoke-Command -ComputerName $domController.HostName -ScriptBlock { $PSVersionTable }
        $psVersion = $PSVer.PSVersion
        $dc = $domController.HostName
        WriteLog "$dc PS version $psVersion"
        Write-Host $domController.HostName "PS version" $PSVer.PSVersion
    }
    catch {
        $doneError = $true
        Write-Host Error
        WriteLog $Error
    }
}

if ($doneError) {
    Write-Host Done with error
}
else {
    Write-Host 
    Write-Host Done!
} 