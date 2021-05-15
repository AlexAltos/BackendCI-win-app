############################
этапы установки/запуска UpdateMachine.v5

* Настройка Master сервера
-- Надо PawerShell 4.0 или выше, проверить текущую версию можено открыв cmd PawerShell (дальше как PS) и выполнить:  $PSVersionTable.PSVersion
-- Открыть консоль PS с правами администратора и выполнить: Set-ExecutionPolicy Bypass
-- Отредактировать "_Resource\Switch_PathProjectSVN.ps1" указав пути репозитория по проектам, которые должны находиться "гдето-роядом" на дисках


-- Для работы со скриптами SQL, нужен SQL server с компонентом управления powershell, или просто установить модуль PS, но для этого надо выход в Inernet: 
Install-Module -Name SqlServer -AllowClobber
Invoke-Sqlcmd -Query "SELECT GETDATE() AS TimeOfQuery;"
Add-PSSnapin SqlServerCmdletSnapin100;
Add-PSSnapin SqlServerProviderSnapin100;
get-PSSnapin –registered

-- если при выполнении Invoke-Sqlcmd -Query "SELECT GETDATE() AS TimeOfQuery;" , вышла  ошибка:
	Invoke-Sqlcmd : При установлении соединения с SQL Server произошла ошибка, связанная с сетью или с определенным экземпл
	яром. Сервер не найден или недоступен. Убедитесь, что имя экземпляра указано правильно и что на SQL Server разрешены уд
	аленные соединения. (provider: Named Pipes Provider, error: 40 - Не удалось открыть подключение к SQL Server) 	
то все ок. модуль установлен и работает, просто проблема в другом, которая щас не важна =)


* Пароли находятся в хранилище Database.v5.kdbx 
-- Используется прога "KeePass", надодится в "_Distr". В файле "Config_Common.ps1" надо указать на её физ расположение. тег внутри файла: $PathKeePassFound 
-- хранилище открывается автоматически паролем, который будет храниться в реестре. для этого надо его указать и запустить в скрипте:
Set-PasswordEncrypted.ps1, тег: -PlainPassword


* Настройка Slave сервера
-- Надо PawerShell 4.0 или выше, проверить текущую версию можено открыв PS и выполнить: $PSVersionTable.PSVersion
-- Открыть консоль PS с правами администратора и выполнить по очереди: 
Set-ExecutionPolicy Bypass
Enable-PSRemoting  -force
winrm enumerate winrm/config/listener
winrm quickconfig
	
-- Для теста, запустить на Master-е, Slave хост : 
get-service -computername 192.168.70.28	
	


############################
Настройка DateBase Server стенда
* создать DateBase c именем: _ServersLogging. И накатить в нее содержимое из "_Resource\SIMADATABASE" 

* Имя кажбой базы, создается в соответвии её разделу и категории
Пример: 
		PreProd44_name1
		PreProd44_name2
		
		Test44_name1
		Test44_name2				
		
* посмотреть версионность установленных проектов, выполняется запросом из хранимки: 
exec  [_ServersLogging].[dbo].ProjectVersionFin
