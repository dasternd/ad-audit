 #
#  This script start audit AD
#  Author: Danil Stepanov, msware.ru (c) 2022
#

# адрес каталога проекта, где будет размещены все входные и выходные файлы
$pathProject = Get-Location 
$pathProject = $pathProject.Path + "\"


function Get-DCs {
    $DCs = @()
    $domControllers = Get-ADDomainController -filter * | Select-Object HostName

    foreach ($DC in $domControllers) {
        $DCs += $DC.HostName
    }

    return $DCs
}

function Get-WindowsEvents {

    $Variables = Get-Content -Path ($pathProject + "settings.json")  -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $EventAgeDays = $Variables.WindowsEvent.daysLastGetEvents
    $CompArr = $DCs
    $LogNames = $Variables.WindowsEvent.logs
    $EventTypes = $Variables.WindowsEvent.eventTypes
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\"
  

    $el_c = @()   #consolidated error log
    $now = Get-Date
    $startdate = $now.AddDays(-$EventAgeDays)
    # $ExportFile = $ExportFolder + "el" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"  # we cannot use standard delimiteds like ":"

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
    # $el_sorted = $el_c | Sort-Object TimeGenerated    #sort by time
    # Write-Host Exporting to $ExportFile
    # $el_sorted | Select EntryType, TimeGenerated, Source, EventID, MachineName | Export-CSV $ExportFile -NoTypeInfo  #EXPORT
    # $el_sorted | Export-CSV $ExportFile -NoTypeInfo  #EXPORT
    Write-Host Done!
}

function Start-AuditAD {
    Get-WindowsEvents
}

Start-AuditAD 