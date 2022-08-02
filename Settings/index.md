# Файл настроек settings.json

Некоторые параметры, используемы для сбора данных для аудита Active Directory, являются переменными и могут изменяться от аудита к аудиту и чтобы не изменять код скриптов для сбора данных, используется файл с настройками.

Файл с настройками **settings.json** должен распологаться в том же каталоге что и скрипт **Start-AuditAD.ps1**. Файлы содержаться в архиве **AuditAD.zip**.

Архив AuditAD.zip необходимо распаковать на любой логический диск на сервер или рабочую станцию на котором преполагается запуск скрипта для сбора данных для аудита Active Directory.

Содержимое распакованного архива AuditAD.zip будет содержать следующие файлы:
- Prerequisite.ps1 (скрипт для проверки готовности инфраструктуры к запуску основного скрипта по сбору данных)
- Start-AuditAD.ps1 (скрипт для запуска сбора данных)
- settings.json (файл настроек)


```json
{
    "workFolder": "Audit",
    "windowsEvent": {
        "folder": "Events",
        "daysLastGetEvents": 30,
        "logs": [
            "Application",
            "System",
            "DFS Replication",
            "Directory Service",
            "DNS Server"
        ],
        "eventTypes": [
            "Error",
            "Warning"
        ]
    },
    "PerformanceMonitor": {
        "daysRun2GetMetrics": 7
    }
}
```