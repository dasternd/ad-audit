Write-Host Exporting info about Computer Info
#Сбор информации о сервере
Get-ComputerInfo > c:\audit\ComputerInfo.txt

Write-Host Exporting info about Precesses
#Сбор информации о запущенных процессах
Get-Process > c:\audit\Process.txt

Write-Host Exporting info about Control Panel
#Сбор информации об установленных панелей управления
Get-ControlPanelItem > c:\audit\ControlPanel.txt

Write-Host Exporting info about Hotfix
#Сбор об установленных исправлениях
Get-HotFix > c:\audit\Hotfix.txt

Write-Host Exporting info about Drive
#Получает диски в текущем сеансе
Get-PSDrive > c:\audit\Drive.txt

Write-Host Exporting info about Service
#Получения служб на сервере
Get-Service > c:\audit\Service.txt

Write-Host Exporting info about Windows Feature
#Получение установленные роли
Get-WindowsFeature > c:\audit\WindowsFeature.txt

Write-Host Exporting info about Software
#Получение установленного ПО
Get-WmiObject -Class Win32_Product > c:\audit\Software.txt

Write-Host Done!