# Файл настроек предназначенный для задания параметров аудита

Для снятия счетчиков производительности (Performance Monitor) необходимо экспортировать группу сборшиков из [XML файла](/Settings/PerfMon-DomainControllerDiagnostics.xml):

```
logman import "Domain Controller Diagnostics" -xml "Domain Controller Diagnostics.xml"
```

По окончанию сбора счеткиков производительности возможно конфертировать .blg файл в .csv файл:

```
relog “Domain Controller Diagnostics.blg” -f csv -o “Domain Controller Diagnostics.csv”
```
