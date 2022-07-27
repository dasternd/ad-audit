# Аудит Active Directory

Все об аудите контроллеров домена и службы каталогов Microsoft Active Directory

Аудит Active Directory одна из важнейших задач для поддержания всей IT инфраструктуры бизнеса. 
Аудит Active Directory:
- выявляет узкие места в системе безопасности и производительности;
- позволяет строить дорожную карту с градацией периодов для последующего исправления и модернизации Active Directory.

Процесс сбора данных для последующего анализа максимально автоматизирован и открыт. Сбор данных выполняется с помощью стандартных командлетов PowerShell и встроенными утилитами Windows.
Необходимо выполнить [предварительные требования](/Prerequisite/) для сбора данный, которые в последующем будут анализироваться.

Осуществляется следующий сбор данных для последующего анализа:
- [Сбор журналов событий (Windows Event)](/WindowsEvent/)
- [Снятие счетчиков производительности (Performance Monitor)](/PerformanceMonitor/)
- Анализ настроек, распространяемых через групповые политики (Group Policy), реестр (Windows Registry) и значениями в базе Active Directory на соответствие рекомендациям Microsoft (Microsoft Security Compliance Toolkit 1.0)
- Инвентаризация оборудования контроллеров домена
- Инвентаризация программного обеспечения установленного на контроллерах домена
- Инвентаризация установленных обновлений
- Сбор информации об установленной операционной системе
- Сбор установленных ролей и компонентов на серверах контроллеров домена
- Запуск и сбор результатов работы утилиты тестирования контроллеров домена Active Directory (DCDIAG)
- Запуск и сбор результатов работы утилиты диагностики и устранения проблем репликации Active Directory (Repadmin)
- Сбор информации об DNS-сервере
- Сбор информации об NTP-сервере
- Сбор информации об открытых портал и правилах брандмауэра

На выходе генерируется [Microsoft Word](/Report/) документ с отображением текущих настроек IT инфраструктуры и Active Directory в частности с дорожной картой рекомендаций по устранению и улучшению безопасности Active Directory.