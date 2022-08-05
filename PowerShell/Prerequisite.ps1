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

Clear-Host
Write-Host "Prerequisite for audit Active Directory"

Write-Host
Write-Host List Domain Controllers
WriteLog "List Domain Controllers"
$domControllers = Get-ADDomainController -filter * | Select-Object HostName
$totalDC = $domControllers.Count

foreach ($domController in $domControllers) {
    Write-Host Connecting to domain controller $domController.HostName ...

    if(Test-Connection -ComputerName $domController.HostName -Count 1 -Quiet){
        WriteLog ("[OK] " + "Test connect to domain controller " + $domController.HostName + " is OK")
        Write-Host Test connect to domain controller $domController.HostName is OK
    }
    else {
        WriteLog ("[Error] " + "Error connected to domain controller " + $domController.HostName)
        Write-Host Error connected to domain controller $domController.HostName
    }
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
        if ($psVersion -ge 5.1){
            WriteLog ("[OK] " + "$dc have PS version $psVersion is OK")
            Write-Host $dc have PS version $psVersion is OK
        }
        else {
            WriteLog ("[Warning] " + "$dc have PS version $psVersion need update PowerShells to version 5.1")
            Write-Host $dc have PS version $psVersion need update PowerShells to version 5.1
        }

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
