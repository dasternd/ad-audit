#Сбор информации о сервере
Get-ComputerInfo > c:\audit\ComputerInfo.txt

#Сбор информации о запущенных процессах
Get-Process > c:\audit\Process.txt

#Сбор информации об установленных панелей управления
Get-ControlPanelItem > c:\audit\ControlPanel.txt

#Сбор об установленных исправлениях
Get-HotFix > c:\audit\Hotfix.txt

#Получает диски в текущем сеансе
Get-PSDrive > c:\audit\Drive.txt

#Получения служб на сервере
Get-Service > c:\audit\Service.txt

#Получение установленные роли
Get-WindowsFeature > c:\audit\WindowsFeature.txt

#Получение установленного ПО
Get-WmiObject -Class Win32_Product > c:\audit\Software.txt