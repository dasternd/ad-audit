# Сбор журналов событий (Windows Event)

Сбор событий в журналах Windows осуществляется средствами скрипта PowerShell [Start-AuditAD.ps1](/PowerShell/Start-AuditAD.ps1).

Сбор осуществляется с фильтрацией на ошибки (**Error**) и придупреждения (**Warning**) с задаваемым периодом, который указывается в [файле настроек](/Settings/) перед запуском скриптов для сбора данных об IT инфраструктуре.

Собираются события со следующих журналов на контроллерах доменов:
- Application
- System
- DFS Replication
- Directory Service
- DNS Server

Данные о событиях сохраняется в .csv файл по следующему формату именования: Events_[FQDN-DC].csv, например, Events_DC1.msware.ru.csv

Файл сохраняется в каталог Events (при отсуствии автоматически создается), который располагается в рабочем каталоге аудита, например, C:\AuditAD\Events\

код функции отвечающий за сбор событий с журналов Windows на контроллерах домена:

```PowerShell
function Get-WindowsEvents {
    $listDCs = Get-DCs
    $eventAgeDays = $fileSettings.WindowsEvent.daysLastGetEvents
    $logNames = $fileSettings.WindowsEvent.logs
    $eventTypes = $fileSettings.WindowsEvent.eventTypes

    $el_c = @()   #consolidated error log
    $now = Get-Date
    $startdate = $now.AddDays(-$eventAgeDays)

    if (!(Test-Path $folderEvents)) {
        Write-Host Created new folder to path $folderEvents
        WriteLog "[Info] Created new folder to path $folderEvents"

        New-Item -Path $folderEvents -ItemType Directory
    }

    foreach ($DC in $listDCs) {

        $ExportFile = $folderEvents + "Events_" + $DC + ".csv"

        if (Test-Path $ExportFile) { 
            Write-Host Discovered old file $ExportFile File removed
            WriteLog "[Info] Discovered old file $ExportFile File removed"
            Remove-Item $ExportFile 
        }

        Write-Host Connecting to Domain Controller $DC ... 
        WriteLog "[Info] Connecting to Domain Controller $DC ..."

        if (Test-Connection -ComputerName $DC -Count 1 -Quiet) {
            Write-Host Connected to Domain Controller $DC is OK
            WriteLog "[OK] Connected to Domain Controller $DC is OK"
            
            foreach ($log in $logNames) {
                try {
                    Write-Host Processing $DC\$log ...
                    WriteLog "[Info] Processing $DC\$log ..."

                    $el = Get-EventLog -ComputerName $DC -Log $log -After $startdate -EntryType $eventTypes
                    $el_c += $el  #consolidating
                }
                catch {
                    Write-Host Error during get events $DC\$log
                    WriteLog "[Error] Error during get events $DC\$log"
                }
            }
            $el_sorted = $el_c | Sort-Object TimeGenerated    #sort by time
            
            Write-Host Exporting Windows Events ...
            WriteLog "[Info] Exporting Windows Events ..."
            
            $el_sorted | Export-CSV $ExportFile -NoTypeInfo
            
            Write-Host Exported Windows Events to $ExportFile OK
            WriteLog "[OK] Exported Windows Events to $ExportFile OK"
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        }
    }
}
```