#
#  This script start audit AD
#  Author: Danil Stepanov, msware.ru (c) 2022
#

# адрес каталога проекта, где будет размещены все входные и выходные файлы
$pathProject = Get-Location 
$pathProject = $pathProject.Path + "\"
$fileSettings = Get-Content -Path ($pathProject + "settings.json")  -Raw | ConvertFrom-Json # загрузка JSON файла настроек
$folderEvents = $pathProject + $fileSettings.WindowsEvent.folder + "\"
$folderInventory = $pathProject + $fileSettings.Inventory.folder + "\"
$folderAD = $pathProject + $fileSettings.AD.folder + "\"
$pathLogFile = $pathProject + "Start-AuditAD-" + (Get-Date).ToString('yyyy_MM_dd_HH_mm') + ".log" 


# ФУНКЦИЯ ЛОГИРОВАНИЯ СОБЫТИЙ
function WriteLog {
    Param ([string]$LogString)
    $LogFile = $pathLogFile
    $DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"
    Add-content $LogFile -value $LogMessage
}

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

function Start-PerformanceMonitors {
    $DCs = Get-DCs
    $CompArr = $DCs
    # $ExportFolder = "\\dc2.msware.ru\AuditAD\PerfMon-DomainControllerDiagnostics.xml"

    foreach ($comp in $CompArr) {
        Invoke-Command -ComputerName $comp -ScriptBlock { C:\Windows\System32\logman.exe import "Domain Controller Diagnostics" -xml \\dc2.msware.ru\AuditAD\PerfMon-DomainControllerDiagnostics.xml }
        Invoke-Command -ComputerName $comp -ScriptBlock { C:\Windows\System32\logman.exe start  "Domain Controller Diagnostics" }
    }
} 

function Start-InventorySoftware {
    $listDCs = Get-DCs
    
    if (!(Test-Path $folderInventory)) {
        Write-Host Created new folder to path $folderInventory
        WriteLog "[Info] Created new folder to path $folderInventory"

        New-Item -Path $folderInventory -ItemType Directory
    }

    foreach ($DC in $listDCs) {

        $ExportFile = $folderInventory + "InventorySoftware_" + $DC + ".csv"

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

            try {
                Write-Host Processing Inventory Software $DC ...
                WriteLog "[Info] Processing Inventory Software $DC ..."
                
                $el = Get-WmiObject -Class Win32_Product -ComputerName $DC
            }
            catch {
                Write-Host Error during get information about installed software $DC\$log
                WriteLog "[Error] Error during get information about installed software $DC\$log"
            }

            Write-Host Exporting Information about Inventory Software ...
            WriteLog "[Info] Exporting Information about Inventory Software ..."

            $el | Export-CSV $ExportFile -NoTypeInfo
            
            Write-Host Exported Information about Inventory Software to $ExportFile OK
            WriteLog "[OK] Exported Information about Inventory Software to $ExportFile OK"
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        }
    }
}

function Start-InventoryHardware {
    $listDCs = Get-DCs
    
    if (!(Test-Path $folderInventory)) {
        Write-Host Created new folder to path $folderInventory
        WriteLog "[Info] Created new folder to path $folderInventory"

        New-Item -Path $folderInventory -ItemType Directory
    }
    
    $Inventory = New-Object System.Collections.ArrayList

    Foreach ($ComputerName in $listDCs) {

        Write-Host Connecting to Domain Controller $ComputerName ... 
        WriteLog "[Info] Connecting to Domain Controller $ComputerName ..."

        if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
            Write-Host Connected to Domain Controller $ComputerName is OK
            WriteLog "[OK] Connected to Domain Controller $ComputerName is OK"

            Write-Host Processing Inventory Hardware ...
            WriteLog "[Info] Processing Inventory Hardware ..."

            $Connection = Test-Connection $ComputerName -Count 1 -Quiet
            $ComputerInfo = New-Object System.Object
            $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value "$ComputerName" -Force
            if ($Connection -eq "True") {
                $ComputerHW = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName | select Manufacturer, Model, NumberOfProcessors, @{Expression = { $_.TotalPhysicalMemory / 1GB }; Label = "TotalPhysicalMemoryGB" }
                $ComputerCPU = Get-WmiObject win32_processor -ComputerName $ComputerName | select DeviceID, Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors
                $ComputerDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName | select DeviceID, VolumeName, @{Expression = { $_.Size / 1GB }; Label = "SizeGB" }
                $ComputerInfoManufacturer = $ComputerHW.Manufacturer
                $ComputerInfoModel = $ComputerHW.Model
                $ComputerInfoNumberOfProcessors = $ComputerHW.NumberOfProcessors
                $ComputerInfoProcessorID = $ComputerCPU.DeviceID
                $ComputerInfoProcessorManufacturer = $ComputerCPU.Manufacturer
                $ComputerInfoProcessorName = $ComputerCPU.Name
                $ComputerInfoNumberOfCores = $ComputerCPU.NumberOfCores
                $ComputerInfoNumberOfLogicalProcessors = $ComputerCPU.NumberOfLogicalProcessors
                $ComputerInfoRAM = $ComputerHW.TotalPhysicalMemoryGB
                $ComputerInfoDiskDrive = $ComputerDisks.DeviceID
                $ComputerInfoDriveName = $ComputerDisks.VolumeName
                $ComputerInfoSize = $ComputerDisks.SizeGB
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "$ComputerInfoManufacturer" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Model" -Value "$ComputerInfoModel" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfProcessors" -Value "$ComputerInfoNumberOfProcessors" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorID" -Value "$ComputerInfoProcessorID" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorManufacturer" -Value "$ComputerInfoProcessorManufacturer" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorName" -Value "$ComputerInfoProcessorName" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfCores" -Value "$ComputerInfoNumberOfCores" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfLogicalProcessors" -Value "$ComputerInfoNumberOfLogicalProcessors" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "RAM" -Value "$ComputerInfoRAM" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskDrive" -Value "$ComputerInfoDiskDrive" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DriveName" -Value "$ComputerInfoDriveName" -Force
                $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Size" -Value "$ComputerInfoSize"-Force
            }
            $Inventory.Add($ComputerInfo) | Out-Null
            $ComputerHW = ""
            $ComputerCPU = ""
            $ComputerDisks = ""
        }
        else {
            Write-Host Domain Controller $ComputerName is not answered
            WriteLog "[Error] Domain Controller $ComputerName is not answered"
        }
    }
    
    $ExportFile = $folderInventory + "InventoryHardware_DomainControllers.csv"
    
    if (Test-Path $ExportFile) {
        Write-Host Discovered old file $ExportFile File removed
        WriteLog "[Info] Discovered old file $ExportFile File removed"

        Remove-Item $ExportFile 
    }

    Write-Host Exporting Inventory Hardware $ComputerName ...
    WriteLog "[Info] Exporting Inventory Hardware $ComputerName ..."
    
    $Inventory | Export-Csv $ExportFile

    Write-Host Exported Information about Inventory Hardware to $ExportFile OK
    WriteLog "[OK] Exported Information about Inventory Hardware to $ExportFile OK"
}

function Start-InventoryHotFix {
    $listDCs = Get-DCs

    if (!(Test-Path $folderInventory)) {
        Write-Host Created new folder to path $folderInventory
        WriteLog "[Info] Created new folder to path $folderInventory"

        New-Item -Path $folderInventory -ItemType Directory
    }

    foreach ($DC in $listDCs) {

        $ExportFile = $folderInventory + "InventoryHotfix_" + $DC + ".csv"

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

            try {
                Write-Host Processing Inventory HotFix $DC ...
                WriteLog "[Info] Processing Inventory HotFix $DC ..."

                $el = Get-HotFix -ComputerName $DC
            }
            catch {
                Write-Host Error during get information about installed HotFix $DC\$log
                WriteLog "[Error] Error during get information about installed HotFix $DC\$log"
            }

            Write-Host Exporting Information about Inventory HotFix ...
            WriteLog "[Info] Exporting Information about Inventory HotFix ..."
    
            $el | Export-CSV $ExportFile -NoTypeInfo
    
            Write-Host Exported Information about Inventory HotFix to $ExportFile
            WriteLog "[OK] Exported Information about Inventory HotFix to $ExportFile"
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        }
    }
}

function Get-InfoOS {
    $listDCs = Get-DCs
    
    if (!(Test-Path $folderInventory)) {
        Write-Host Created new folder to path $folderInventory
        WriteLog "[Info] Created new folder to path $folderInventory"

        New-Item -Path $folderInventory -ItemType Directory
    }
    
    $Inventory = New-Object System.Collections.ArrayList

    Foreach ($DC in $listDCs) {

        $ExportFile = $folderInventory + "InfoOS_" + $DC + ".csv"

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

            $OSInfo = New-Object System.Object
            $OSInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value "$DC" -Force
        
            try {
                Write-Host Processing Get Information about OS $DC ...
                WriteLog "[Info] Processing Get Information about OS $DC ..."

                $ComputerInfo = Invoke-Command -ComputerName $DC -ScriptBlock { Get-ComputerInfo }

                #$ComputerInfo =  Get-ComputerInfo -ComputerName $ComputerName

                $OSInfo | Add-Member -MemberType NoteProperty -Name "Windows Current Version" -Value $ComputerInfo.WindowsCurrentVersion -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Windows Product Name" -Value $ComputerInfo.WindowsProductName -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Windows System Root" -Value $ComputerInfo.WindowsSystemRoot -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Windows Version" -Value $ComputerInfo.WindowsVersion  -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Name" -Value $ComputerInfo.OsName -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Type" -Value $ComputerInfo.OsType -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Version" -Value $ComputerInfo.OsVersion -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Build Number" -Value $ComputerInfo.OsBuildNumber -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Windows Directory" -Value $ComputerInfo.OsWindowsDirectory -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Locale" -Value $ComputerInfo.OsLocale -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Install Date" -Value $ComputerInfo.OsInstallDate -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Language" -Value $ComputerInfo.OsLanguage -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Os Server Level" -Value $ComputerInfo.OsServerLevel -Force
                $OSInfo | Add-Member -MemberType NoteProperty -Name "Time Zone" -Value $ComputerInfo.TimeZone -Force
            }
            catch {
                Write-Host Error during get information about OS $DC\$log
                WriteLog "[Error] Error during get information about OS $DC\$log"
            }
            $Inventory.Add($OSInfo) | Out-Null

            Write-Host Exporting Information about OS 
            WriteLog "[OK] Exporting Information about OS"
        
            $Inventory | Export-Csv $ExportFile

            Write-Host Exported Information about OS to $ExportFile
            WriteLog "[OK] Exported Information about OS to $ExportFile"
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        }
    }
}

function Get-WindowsFeature {
    $listDCs = Get-DCs
    
    if (!(Test-Path $folderInventory)) {
        Write-Host Created new folder to path $folderInventory
        WriteLog "[Info] Created new folder to path $folderInventory"

        New-Item -Path $folderInventory -ItemType Directory
    }

    foreach ($DC in $listDCs) {

        $ExportFile = $folderInventory + "WindowsFeature_" + $DC + ".csv"

        if (Test-Path $ExportFile) {
            Write-Host Discovered old file $ExportFile File removed
            WriteLog "[Info] Discovered old file $ExportFile File removed"

            Remove-Item $ExportFile 
        }

        if (Test-Connection -ComputerName $DC -Count 1 -Quiet) {
            Write-Host Connected to Domain Controller $DC is OK
            WriteLog "[OK] Connected to Domain Controller $DC is OK"

            try {
                
                Write-Host Processing Get Information Installed Windows Feature $DC
                WriteLog "[OK] Processing Get Information Installed Windows Feature $DC"
                
                $WindowsFeature = Invoke-Command -ComputerName $DC -ScriptBlock { Get-WindowsFeature }
            }
            catch {
                Write-Host Error during Inventory Installes Windows Feature $DC
                WriteLog "[Info] Error during Inventory Installes Windows Feature $DC"
            }

            Write-Host Exporting Information about Inventory Software ...
            WriteLog "[Info] Exporting Information about Inventory Windows Feature ..."

            $WindowsFeature | Export-CSV $ExportFile -NoTypeInfo
            
            Write-Host Exported Information about Inventory Windows Feature to $ExportFile OK
            WriteLog "[OK] Exported Information about Inventory Windows Feature to $ExportFile OK"
        
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        } 
    }
}

function Start-DCDIAG {
    $listDCs = Get-DCs
    
    if (!(Test-Path $folderAD)) {
        Write-Host Created new folder to path $folderAD
        WriteLog "[Info] Created new folder to path $folderAD"

        New-Item -Path $folderAD -ItemType Directory
    }

    foreach ($DC in $listDCs) {

        $ExportFile = $folderAD + "DCDIAG_" + $DC + ".txt"
    
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

            try {
                Write-Host Processing Start DCDIAG $DC ...
                WriteLog "[Info] Processing Start DCDIAG $DC ..."

                $DCDIAG = Invoke-Command -ComputerName $DC -ScriptBlock { DCDIAG } # тут нужно дописать команду
            }
            catch {
                Write-Host Error during Start DCDIAG $DC\$log
                WriteLog "[Error] Error during Start DCDIAG $DC\$log"
            }

            Write-Host Exporting Result DCDIAG ...
            WriteLog "[Info] Exporting Result DCDIAG ..."

            $DCDIAG | Out-File $ExportFile

            Write-Host Exporting Result DCDIAG to $ExportFile OK
            WriteLog "[OK] Exporting Result DCDIAG to $ExportFile OK"
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        }
    }
}

function Start-Repadmin {
    $listDCs = Get-DCs
    
    if (!(Test-Path $folderAD)) {
        Write-Host Created new folder to path $folderAD
        WriteLog "[Info] Created new folder to path $folderAD"

        New-Item -Path $folderAD -ItemType Directory
    }

    foreach ($DC in $listDCs) {
    
        $ExportFile = $folderAD + "REPADMIN_" + $DC + ".txt"
    
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

            try {
                Write-Host Processing Start REPADMIN $DC ...
                WriteLog "[Info] Processing Start REPADMIN $DC ..."

                $REPADMIN = Invoke-Command -ComputerName $DC -ScriptBlock { repadmin /replsummary } # тут нужно дописать команду
            }
            catch {
                Write-Host Error during Start REPADMIN $DC\$log
                WriteLog "[Error] Error during Start REPADMIN $DC\$log"
            }

            Write-Host Exporting Result REPADMIN ...
            WriteLog "[Info] Exporting Result REPADMIN ..."

            $REPADMIN | Out-File $ExportFile

            Write-Host ExportedResult REPADMIN to $ExportFile OK
            WriteLog "[OK] Exported Result REPADMIN to $ExportFile OK"
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        }
    }
}

function Get-InfoDNS {
    $listDCs = Get-DCs
    
    if (!(Test-Path $folderAD)) {
        Write-Host Created new folder to path $folderAD
        WriteLog "[Info] Created new folder to path $folderAD"

        New-Item -Path $folderAD -ItemType Directory
    }

    foreach ($DC in $listDCs) {

        $ExportFile = $folderAD + "InfoDNS_" + $DC + ".txt"
    
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

            try {
                Write-Host Processing Start InfoDNS $DC ...
                WriteLog "[Info] Processing Start InfoDNS $DC ..."

                $infoDNS = Get-DnsServer
                }
            catch {
                Write-Host Error during Start InfoDNS $DC\$log
                WriteLog "[Error] Error during Start InfoDNS $DC\$log"
            }

            Write-Host Exporting Result InfoDNS ...
            WriteLog "[Info] Exporting Result InfoDNS ..."

            $infoDNS | Out-File $ExportFile

            Write-Host Exported Result InfoDNS to $ExportFile OK
            WriteLog "[OK] Exported Result InfoDNS to $ExportFile OK"
        }
        else {
            Write-Host Domain Controller $DC is not answered
            WriteLog "[Error] Domain Controller $DC is not answered"
        }
    }
}

function Start-AuditAD {
    $totalSteps = 9
    $step = 0
    Clear-Host
    
    Write-Host START AUDIT ACTIVE DIRECTORY
    WriteLog "START AUDIT ACTIVE DIRECTORY"

    Write-Host
    $step++
    Write-Host GET INFORMATION ABOUT WINDOWS EVENTS [($step)/ $totalSteps ]
    WriteLog ("GET INFORMATION ABOUT WINDOWS EVENTS [ " + $step + " / $totalSteps ]")
    Get-WindowsEvents

    <#     Write-Host
    $step++
    Write-Host START PERFORMANCE MONITORS [$step/ $totalSteps ] 
    WriteLog ("START PERFORMANCE MONITORS [ " + $step + " / $totalSteps ]")
    Start-PerformanceMonitors #>
    
    Write-Host
    $step++
    Write-Host START INVENTORY SOFTWARE [($step)/ $totalSteps ]
    WriteLog ("START INVENTORY SOFTWARE [ " + $step + " / $totalSteps ]")
    Start-InventorySoftware
    
    Write-Host
    $step++
    Write-Host START INVENTORY HARDWARE [($step)/ $totalSteps ]
    WriteLog ("START INVENTORY HARDWARE [ " + $step + " / $totalSteps ]")
    Start-InventoryHardware
    
    Write-Host
    $step++
    Write-Host START INVENTORY HOTFIXes [($step)/ $totalSteps ]
    WriteLog ("START INVENTORY HOTFIXes [ " + $step + " / $totalSteps ]")
    Start-InventoryHotFix

    Write-Host
    $step++
    Write-Host GET INFORMATION ABOUT OS [($step)/ $totalSteps ]
    WriteLog ("GET INFORMATION ABOUT OS [ " + $step + " / $totalSteps ]")
    Get-InfoOS

    Write-Host
    $step++
    Write-Host GET INFORMATION ABOUT INSTALLED WINDOWS FEATURE [($step)/ $totalSteps ]
    WriteLog ("GET INFORMATION ABOUT INSTALLED WINDOWS FEATURE [ " + $step + " / $totalSteps ]")
    Get-WindowsFeature

    Write-Host
    $step++
    Write-Host START TEST DCDIAG [($step)/ $totalSteps ]
    WriteLog ("START TEST DCDIAG [ " + $step + " / $totalSteps ]")
    Start-DCDIAG

    Write-Host
    $step++
    Write-Host START TEST REPADMIN [($step)/ $totalSteps ]
    WriteLog ("START TEST REPADMIN [ " + $step + " / $totalSteps ]")
    Start-Repadmin

    Write-Host
    $step++
    Write-Host GET INFORMATION ABOUT DNS [($step)/ $totalSteps ]
    WriteLog ("GET INFORMATION ABOUT DNS [ " + $step + " / $totalSteps ]")
    Get-InfoDNS

    Write-Host
    Write-Host "ZIPing all data files to archive ..."
    $folder = Get-Location
    $fileZIP = $folder.Path + "\ResultAuditAD.zip"
    if (!(Test-Path $fileZIP)) {
        Compress-Archive -Path ($folder.Path + "\*") -DestinationPath $fileZIP 
    }
    else {
        Remove-Item $fileZIP
        Compress-Archive -Path ($folder.Path + "\*") -DestinationPath $fileZIP 
    }
    Write-Host "Archive with all data files created to $fileZIP"

    Write-Host DONE!
} 

Start-AuditAD 