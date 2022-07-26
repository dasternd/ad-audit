Write-Host Exporting info about Domain
#Получение информации о домене
Get-ADDomain > c:\audit\ad\ADDomain.txt

Write-Host Exporting info about Domain Controller
#Получение информации обо всех контроллерах домена
Get-ADDomainController -filter * > c:\audit\ad\ADDomainController.txt

Write-Host Exporting info about Forest
#Получение информации о лесе
Get-ADForest > c:\audit\ad\ADForest.txt

Write-Host Exporting info about DNS
#Получение информации о DNS
Get-DnsServer > c:\audit\ad\DNSSserver.txt

Write-Host Done!