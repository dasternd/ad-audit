#Получение информации о домене
Get-ADDomain > c:\audit\ad\ADDomain.txt

#Получение информации обо всех контроллерах домена
Get-ADDomainController -filter * > c:\audit\ad\ADDomainController.txt

#Получение информации о лесе
Get-ADForest > c:\audit\ad\ADForest.txt

#Получение информации о DNS
Get-DnsServer > c:\audit\ad\DNSSserver.txt