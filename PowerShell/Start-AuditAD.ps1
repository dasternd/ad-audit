 #
#  This script start audit AD
#  Author: Danil Stepanov, msware.ru (c) 2022
#

# адрес каталога проекта, где будет размещены все входные и выходные файлы
$pathProject = Get-Location 
$pathProject = $pathProject.Path + "\"

# получение списка контроллеров домена Active Directory
function Get-DCs {
    $DCs = @()
    $domControllers = Get-ADDomainController -filter * | Select-Object HostName

    foreach ($DC in $domControllers) {
        $DCs += $DC.HostName
    }

    return $DCs
}

# получение событий с журналов Windows со всех контроллеров доменов Active Directory
function Get-WindowsEvents {

    $Variables = Get-Content -Path ($pathProject + "settings.json")  -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $EventAgeDays = $Variables.WindowsEvent.daysLastGetEvents
    $CompArr = $DCs
    $LogNames = $Variables.WindowsEvent.logs
    $EventTypes = $Variables.WindowsEvent.eventTypes
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.WindowsEvent.folder + "\"

    if (!(Test-Path $ExportFolder)) {
        New-Item -Path $ExportFolder -ItemType Directory
    }

    $el_c = @()   #consolidated error log
    $now = Get-Date
    $startdate = $now.AddDays(-$EventAgeDays)

    foreach ($comp in $CompArr) {

        $ExportFile = $ExportFolder + $comp + "_Events_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"

        foreach ($log in $LogNames) {
            Write-Host Processing $comp\$log
            $el = Get-EventLog -ComputerName $comp -Log $log -After $startdate -EntryType $EventTypes
            $el_c += $el  #consolidating
        }
        $el_sorted = $el_c | Sort-Object TimeGenerated    #sort by time
        Write-Host Exporting to $ExportFile
        $el_sorted | Export-CSV $ExportFile -NoTypeInfo
    }

    Write-Host Done!
}

function Start-PerformanceMonitors {
    $DCs = Get-DCs
    $CompArr = $DCs
    # $ExportFolder = "\\dc2.msware.ru\AuditAD\PerfMon-DomainControllerDiagnostics.xml"

    foreach ($comp in $CompArr) {
       # Invoke-Command -ComputerName $comp -ScriptBlock { C:\Windows\System32\logman.exe import "Domain Controller Diagnostics" -xml \\dc2.msware.ru\AuditAD\PerfMon-DomainControllerDiagnostics.xml }
       # Invoke-Command -ComputerName $comp -ScriptBlock { C:\Windows\System32\logman.exe start  "Domain Controller Diagnostics" }
        logman import "Domain Controller Diagnostics" -xml \\dc2.msware.ru\AuditAD\PerfMon-DomainControllerDiagnostics.xml -s $comp
        logman start "Domain Controller Diagnostics" -s $comp
    }
} 

function Start-AuditAD {
    #Write-Host GET INFORMATION ABOUT WINDOWS EVENTS [1/2]
    #Get-WindowsEvents

    Write-Host START PERFORMANCE MONITORS [2/2]
    Start-PerformanceMonitors

    Write-Host DONE!
}

Start-AuditAD 