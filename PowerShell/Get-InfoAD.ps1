#Получение информации о домене
Get-ADDomain > c:\audit\ad\addomain.txt

#Получение информации обо всех контроллерах домена
Get-ADDomainController -filter * > c:\audit\ad\addomaincontroller.txt

#Получение информации о лесе
Get-ADForest > c:\audit\ad\adForest.txt

#Получение информации о DNS
Get-DnsServer > c:\audit\ad\dnsserver.txt