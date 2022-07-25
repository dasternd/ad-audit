#Сбор информации о сервере
Get-ComputerInfo > c:\audit\computerinfo.txt

#Сбор информации о запущенных процессах
Get-Process > c:\audit\process.txt

#Сбор информации об установленных панелей управления
Get-ControlPanelItem > c:\audit\controlpanel.txt

#Сбор об установленных исправлениях
Get-HotFix > c:\audit\hotfix.txt

#Получает диски в текущем сеансе
Get-PSDrive > c:\audit\drive.txt

#Получения служб на сервере
Get-Service > c:\audit\service.txt

#Получение установленные роли
Get-WindowsFeature > c:\audit\windowsfeature.txt

#Получение установленного ПО
Get-WmiObject -Class Win32_Product > c:\audit\software.txt