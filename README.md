# Аудит Active Directory

Аудит Active Directory одна из важнейших задач для поддержания всей IT инфраструктуры бизнеса. 

Аудит Active Directory:
- выявляет узкие места в системе безопасности и производительности;
- позволяет строить дорожную карту, разделяя на периоды для последующего исправления и модернизации Active Directory.

Для проведения аудита Active Directory требуется выполнить [предварительные требования](/Prerequisite/), необходимые для сбора данных, которые в последующем будут анализироваться.

[Процесс сбора данных](/Steps/) для последующего анализа максимально автоматизирован и открыт. Сбор данных выполняется с помощью стандартных командлетов PowerShell и встроенными утилитами Windows.

Осуществляется следующий сбор данных для последующего анализа:
- ✅ Сбор [журналов событий](/WindowsEvent/) (**Windows Event**)
- ❗️ Снятие [счетчиков производительности](/PerformanceMonitor/) (**Performance Monitor**)
- Анализ [настроек](/Baseline/), распространяемых через групповые политики (**Group Policy**), реестр (**Windows Registry**) и значениями в базе Active Directory на соответствие рекомендациям Microsoft ([Microsoft Security Compliance Toolkit 1.0](https://www.microsoft.com/en-us/download/details.aspx?id=55319))
- ✅ Инвентаризация [оборудования](/InventoryHardware/) контроллеров домена
- ✅ Инвентаризация [программного обеспечения](/InventorySoftware/) установленного на контроллерах домена
- ✅ Инвентаризация [обновлений](/InventoryUpdate/) установленных на контроллерах домена
- ✅ Сбор информации об установленной [операционной системе](/InfoOS/) на контроллерах домена
- Сбор установленных [ролей и компонентов](/Features/) на серверах контроллеров домена
- ✅ Запуск и сбор результатов работы [утилиты тестирования контроллеров домена Active Directory](/DCDIAG/)  (**DCDIAG**)
- ✅ Запуск и сбор результатов работы [утилиты диагностики и устранения проблем репликации Active Directory](/Repadmin/) (**Repadmin**)
- ✅ Сбор информации об [DNS-сервере](/DNS/)
- Сбор информации об [NTP-сервере](/NTP/)
- Сбор информации об открытых портал и правилах [брандмауэра](/Firewall/)
- Сбор информации о количестве объектов в Active Directory (Пользователи, Компьютеры) - отключенный / активные
- Сбор информации об учетных записях с повышенными правами (Администратор домена, Администратор предприятия, Администратор схемы, Администратор)
- Сбор информации о версиях операционных систем в доменной локальной сети

На выходе генерируется [Microsoft Word](/Report/) документ с отображением текущих настроек IT инфраструктуры и Active Directory в частности, с дорожной картой рекомендаций по устранению и улучшению безопасности Active Directory.