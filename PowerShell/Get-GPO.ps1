Backup-Gpo -All -Path "c:\temp\"

Get-GPOReport -All -Domain "msware.ru" -Server "DC1" -ReportType XML -Path "C:\temp\ReportGPO.xml"

Get-GPOReport -All -Domain "msware.ru" -Server "DC1" -ReportType HTML -Path "C:\temp\ReportGPO.html"

