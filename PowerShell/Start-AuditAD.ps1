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
       Invoke-Command -ComputerName $comp -ScriptBlock { C:\Windows\System32\logman.exe import "Domain Controller Diagnostics" -xml \\dc2.msware.ru\AuditAD\PerfMon-DomainControllerDiagnostics.xml }
       Invoke-Command -ComputerName $comp -ScriptBlock { C:\Windows\System32\logman.exe start  "Domain Controller Diagnostics" }
    }
} 

function Start-InventorySoftware {
    $Variables = Get-Content -Path ($pathProject + "settings.json")  -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $CompArr = $DCs
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.Inventory.folder + "\"

    if (!(Test-Path $ExportFolder)) {
        New-Item -Path $ExportFolder -ItemType Directory
    }

    $now = Get-Date
    
    foreach ($comp in $CompArr) {

        $ExportFile = $ExportFolder + $comp + "_InventorySoftware_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"

        Write-Host Processing Inventory Software $comp

        $el = Get-WmiObject -Class Win32_Product -ComputerName $comp

        Write-Host Exporting to $ExportFile
        $el | Export-CSV $ExportFile -NoTypeInfo
    }

    Write-Host Done!
}

function Start-InventoryHardware {
    $Variables = Get-Content -Path ($pathProject + "settings.json")  -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $CompArr = $DCs
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.Inventory.folder + "\"

    if (!(Test-Path $ExportFolder)) {
        New-Item -Path $ExportFolder -ItemType Directory
    }

    $now = Get-Date
    
    $Inventory = New-Object System.Collections.ArrayList
    $AllComputers = $CompArr 
    $AllComputersNames = $AllComputers
    Foreach ($ComputerName in $AllComputersNames) {
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
    
        $ExportFile = $ExportFolder + "InventoryHardware_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"
    
        Write-Host Processing Inventory Software $comp
    
    $Inventory | Export-Csv $ExportFile

    Write-Host Done!
}

function Start-InventoryHotFix {
    $Variables = Get-Content -Path ($pathProject + "settings.json")  -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $CompArr = $DCs
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.Inventory.folder + "\"

    if (!(Test-Path $ExportFolder)) {
        New-Item -Path $ExportFolder -ItemType Directory
    }

    $now = Get-Date

    foreach ($comp in $CompArr) {

        $ExportFile = $ExportFolder + $comp + "_InventoryHotfix_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"

        Write-Host Processing Inventory Software $comp

        $el =  Get-HotFix -ComputerName $comp

        Write-Host Exporting to $ExportFile
        $el | Export-CSV $ExportFile -NoTypeInfo
    }

    Write-Host Done!
}

function Get-InfoOS {
    $Variables = Get-Content -Path ($pathProject + "settings.json")  -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $CompArr = $DCs
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.Inventory.folder + "\"

    if (!(Test-Path $ExportFolder)) {
        New-Item -Path $ExportFolder -ItemType Directory
    }

    $now = Get-Date
    
    $Inventory = New-Object System.Collections.ArrayList
    $AllComputers = $CompArr 
    $AllComputersNames = $AllComputers

    Foreach ($ComputerName in $AllComputersNames) {
        Write-Host Processing Get Information about OS $comp

        $Connection = Test-Connection $ComputerName -Count 1 -Quiet
        $OSInfo = New-Object System.Object
        $OSInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value "$ComputerName" -Force
        if ($Connection -eq "True") {
            $ComputerInfo =  Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-ComputerInfo }

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
        $Inventory.Add($OSInfo) | Out-Null
    }

    $ExportFile = $ExportFolder + "InfoOS_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"
    
    Write-Host Exporting to $ExportFile
    $Inventory | Export-Csv $ExportFile

    Write-Host Done!
}

function Get-WindowsFeature {
    $Variables = Get-Content -Path ($pathProject + "settings.json") -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $CompArr = $DCs
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.Inventory.folder + "\"

    foreach ($comp in $CompArr) {

        $WindowsFeature = Invoke-Command -ComputerName $comp -ScriptBlock { Get-WindowsFeature }

        Write-Host Processing Get Information Installed Windows Feature $comp

        $ExportFile = $ExportFolder + $comp + "_WindowsFeature_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"

        $WindowsFeature | Export-CSV $ExportFile -NoTypeInfo
    }

    Write-Host Done!
}

function Start-DCDIAG {
    $Variables = Get-Content -Path ($pathProject + "settings.json") -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $CompArr = $DCs
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.Inventory.folder + "\"

    foreach ($comp in $CompArr) {
    
        $DCDIAG = Invoke-Command -ComputerName $comp -ScriptBlock {} # тут нужно дописать команду

        Write-Host Processing Start DCDIAG $comp

        $ExportFile = $ExportFolder + $comp + "_DCDIAG_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"

        $DCDIAG | Export-CSV $ExportFile -NoTypeInfo
    }

    Write-Host Done!
}

function Start-Repadmin {
    $Variables = Get-Content -Path ($pathProject + "settings.json") -Raw | ConvertFrom-Json # загрузка JSON файла настроек
    $DCs = Get-DCs
    $CompArr = $DCs
    $ExportFolder = Get-Location
    $ExportFolder = $ExportFolder.Path + "\" + $Variables.Inventory.folder + "\"

    foreach ($comp in $CompArr) {
    
        $REPADMIN = Invoke-Command -ComputerName $comp -ScriptBlock {} # тут нужно дописать команду

        Write-Host Processing Start REPADMIN $comp

        $ExportFile = $ExportFolder + $comp + "_REPADMIN_" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"

        $REPADMIN | Export-CSV $ExportFile -NoTypeInfo
    }

    Write-Host Done!
}

function Start-AuditAD {
    $totalSteps = 4
    $step = 1
    
    # Write-Host GET INFORMATION ABOUT WINDOWS EVENTS [($step++)/$totalSteps]
    # Get-WindowsEvents

    # Write-Host START PERFORMANCE MONITORS [++$step/$totalSteps] 
    # Start-PerformanceMonitors
    
    # Write-Host START INVENTORY SOFTWARE [($step++)/$totalSteps]
    # Start-InventorySoftware
    
    # Write-Host START INVENTORY SOFTWARE [($step++)/$totalSteps]
    # Start-InventoryHardware
    
    # Write-Host START INVENTORY HOTFIXes [($step++)/$totalSteps]
    # Start-InventoryHotFix

    # Write-Host GET INFORMATION ABOUT OS [($step++)/$totalSteps]
    # Get-InfoOS

    Write-Host GET INFORMATION ABOUT INSTALLED WINDOWS FEATURE [($step++)/$totalSteps]
    Get-WindowsFeature

    Write-Host START TEST DCDIAG [($step++)/$totalSteps]
    Start-DCDIAG

    Write-Host START TEST REPADMIN [($step++)/$totalSteps]
    Start-Repadmin

    Write-Host DONE!
} 


Start-AuditAD 