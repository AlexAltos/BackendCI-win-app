## _ModuleFunction.ps1

Function Get-PasswordFromKeePass() {
<# 
.SYNOPSIS Эта функция шифрует пароль и сохраняет в реестр для последующего получения функцией Get-PasswordFromKeePass. 
.DESCRIPTION Эта функция сохранит пароль, зашифрованный таким образом, что пароль сможет расшифровать только текущая учетная запись, в кусте реестра HKCU текущей учетной записи. Пароль в последующем может быть использован функцией Get-PasswordFromKeePass. 
.PARAMETER Name Имя пароля, необходимо для последующего извлечения этого пароля из реестра. 
.PARAMETER PlainPassword Пароль в виде нешифрованного текста. 
.EXAMPLE Set-PasswordEncrypted -Name 'saqwel' -PlainPassword 'P@ssw0rd'
#> 

    param(
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$PathKeePass,         #Путь до KeePass "d:\Program\KeePass Password Safe 2\KeePass.exe"
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$PathKeePassDatabase, #Путь до KeePassDatabase d:\Database.kdbx
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$ParentGroupName,     #Раздел с паролем
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$Title                #Нужный пункт
    )

    # Пароль от KeePass хранится в кусте реестра
    $RegPath = "HKCU:\Software\Passwords"
    # Параметр, который хранит зашифрованный пароль, тот что был указан при запуске - PasswordEncrypted
    $Encrypted = (Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue).KeePassPassword 
    Function EnterKeePass () {            
        # Получить пароль готовый для открытия базы паролей KeePass
        $KeePass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString))   
        # Загрузить класс из KeePass.exe:
        [Reflection.Assembly]::LoadFile("$PathKeePass") | Out-Null
        # Получить параметры, необходимые для подключения к базе KeePass
        $KcpUserAccount = New-Object -TypeName KeePassLib.Keys.KcpUserAccount
        $KcpPassword    = New-Object -TypeName KeePassLib.Keys.KcpPassword($KeePass)
        $CompositeKey   = New-Object -TypeName KeePassLib.Keys.CompositeKey 
        $CompositeKey.AddUserKey( $KcpPassword )
 
        # Требуется файл .KDBX для открытия базы данных KeePass
        $IOConnectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
        $IOConnectionInfo.Path = "$PathKeePassDatabase" 
        $PwDatabase = New-Object -TypeName KeePassLib.PwDatabase
        $PwDatabase.Open($IOConnectionInfo, $CompositeKey, $Null)  

        # Получить требуемый пароль
        $PwCollection = $PwDatabase.RootGroup.GetEntries($True) | Where{ $_.ParentGroup.Name -eq $ParentGroupName -and $_.Strings.ReadSafe("Title") -eq $Title }                        
        $PwDatabase.Close() 

        # Вернуть только один пароль и логин пользователя
        If($PwCollection.Uuid.Count -eq 1) {
            $Object = @{
                Password = $PwCollection.Strings.ReadSafe("Password")
                UserName = $PwCollection.Strings.ReadSafe("UserName")
				URL = $PwCollection.Strings.ReadSafe("URL")
				Notes = $PwCollection.Strings.ReadSafe("Notes")
            }
        } else {
            $Object = $False
        }
 
        return $Object	
    }

    # Проверяем есть ли в реестре запись. и делаем развилку ввода пароля
    IF($Encrypted) {
        # Перед расшифровшкой пароля надо его конвертировать
        $SecureString  = $Encrypted | ConvertTo-SecureString
        EnterKeePass
    } else { # если нет, то вводим ее руками   
        Write-host "`nKeePass in Reestr not found" -ForegroundColor red -BackgroundColor black
        Write-host $PathKeePassDatabase	                     
        do {
            $error.Clear()                                   
            $SecureString = Read-Host 'Password Database' -AsSecureString     
          
        try {EnterKeePass}
        Catch  {"Failed"}
        Finally {""}
                      
        } while ($Error.Count -gt 0)
    }
}

Function Set-PasswordEncrypted() {
<# 
.SYNOPSIS Эта функция шифрует пароль и сохраняет в реестр для последующего получения функцией Get-PasswordFromKeePass. 
.DESCRIPTION Эта функция сохранит пароль, зашифрованный таким образом, что пароль сможет расшифровать только текущая учетная запись, в кусте реестра HKCU текущей учетной записи. Пароль в последующем может быть использован функцией Get-PasswordFromKeePass. 
.PARAMETER Name Имя пароля, необходимо для последующего извлечения этого пароля из реестра. 
.PARAMETER PlainPassword Пароль в виде нешифрованного текста. 
.EXAMPLE Set-PasswordEncrypted -Name 'saqwel' -PlainPassword 'P@ssw0rd' 
#>
     param(
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$Name,
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][string]$PlainPassword
    )
 
    $SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
    $RegPath = "HKCU:\Software\Passwords"
    if(!(Test-Path -Path $RegPath)) {
        New-Item -Path $RegPath -Confirm:$false -Force -ErrorAction Stop | Out-Null
    } else {
        New-ItemProperty -Path $RegPath -Name $Name -Value $SecurePassword -Force -ErrorAction Stop | Out-Null
    }

    #Set-PasswordEncrypted -Name 'KeePassPassword' -PlainPassword '123456789' 
}


function CompileRelease {
	param (
		$PathProjectSVN
    )

    "Update to HEAD revision"
    svn up $PathProjectSVN

    "`tGenerate assembly files"
    wscript "$PathProjectSVN\_scripts\PostUpdate.js" null 0 0 null $PathProjectSVN
           
    "`tBuilding references libs"
    $MSBuild = & "$PathProjectSVN\_scripts\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe 
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,Platform="Any CPU" "$PathProjectSVN\Lzma\Lzma.sln"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,Platform="Any CPU" "$PathProjectSVN\Controls\Controls.sln"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,Platform="Any CPU" "$PathProjectSVN\PopUpWindows\PopupWindows.sln"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,/p:Platform="Any CPU" "$PathProjectSVN\CertificateServiceV2\SabCertService.sln"

    "`tBuilding secondary projects"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release /p:Platform="Any CPU" "$PathProjectSVN\UpdateManager\UpdateManager.sln"

    "`tBuilding main solutions"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release /p:Platform="Any CPU" "$PathProjectSVN\Sima.sln"

}


# -------------------------------------------
# Получаем версии SVN
Function VersionSVN {
    param (
        $SectionProject,
        $PathProjectSVN,
        $ProjectType,
		$Project		
    )
    	
    $FMajor = "0" 
    $FMinor = ""
    $CMinor = ""

	# читаем мажорную версию из Branch для проекта 44
	if (!($ProjectType -eq "Test") -and !($SectionProject -eq "Other") ) { 
		$FMajor = (svn log --stop-on-copy $PathProjectSVN)
		$FMajor = $FMajor[-5..- 1] 
		$FMajor = $FMajor[1] 
		$FMajor = $FMajor.Substring(1,5)
	}
	# текущий коммит в Branch
	$CMinor = (svn log -l 1 -q -r COMMITTED $PathProjectSVN)
	$CMinor = $CMinor[1] 
	$CMinor = $CMinor.Substring(1,5)

	# Будущий коммит 
	$FMinor = (svn log -l 1 -q -r HEAD:BASE $PathProjectSVN)
	IF( $FMinor.Length -eq 3){
		$FMinor = $FMinor[1] 
		$FMinor = $FMinor.Substring(1,5)
	} else {$FMinor = $CMinor}

	@($FMajor, $FMinor, $CMinor, "--")
}


# Проверка на присутсвие
function UMChecker {
	Param (
		[PARAMETER(Mandatory=$false)][String] $TestPath,        
        [PARAMETER(Mandatory=$false)][String] $ServiseName,	
		[PARAMETER(Mandatory=$false)][String] $ServisePath	
	)	
	$errorr = 0
	
	# тест пути
	if ($TestPath)  {	
		$body = $TestPath
		if(Test-Path $TestPath -ErrorAction SilentlyContinue)  {
			$result='Ok'
		} 
		else  {
			$result='not found' 
			$errorr ++
		}												
	}
					
	# Проверка сервесов
	if ($ServiseName) {
		$body = "$ServisePath $ServiseName"
		if ( $svc = (get-service -computername $ServisePath -name $ServiseName -ErrorAction SilentlyContinue ) ) {	
			$result= "$($svc.status)"
		}
		else  {
			$result= "not found"
			$errorr++
		}			
	}									
	
	@($body, $result, $errorr)
}

# Проверка связи БД		
function Test-SQLDatabase  {
	param( 
	[Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True)] [string] $Server,
	[Parameter(Position=1, Mandatory=$True)] [string] $Database,
	[Parameter(Position=2, Mandatory=$True, ParameterSetName="SQLAuth")] [string] $Username,
	[Parameter(Position=3, Mandatory=$True, ParameterSetName="SQLAuth")] [string] $Password,
	[Parameter(Position=2, Mandatory=$True, ParameterSetName="WindowsAuth")] [switch] $UseWindowsAuthentication
	)
    
	$errorr = 0       
		$dbConnection = New-Object System.Data.SqlClient.SqlConnection
		#выбираем конект стринг для БД
		if (!$UseWindowsAuthentication)  {
			$dbConnection.ConnectionString = "Data Source=$Server; uid=$Username; pwd=$Password; Database=$Database;"
			$authentication = "SQL ($Username)"
		} else  {
			$dbConnection.ConnectionString = "Data Source=$Server; Database=$Database;Integrated Security=True;"
			$authentication = "Windows ($env:USERNAME)"
		}
		
		$body = $Server +" "+ $Database	 
		try {   #Пишем, если все было успешно
			$connectionTime = measure-command {$dbConnection.Open()}            
			$result= "Ok"
		}        
		catch  {   #Пишем, если конект не был произведен			
			$result= "Failed"
			$errorr++
            #$error.Clear()                                   
		}
		Finally {
			$dbConnection.Close()
		}        
       @($body, $result, $errorr) 


# запуск теста БД	
# (Test-SQLDatabase -Server $BDserver -Database $BD -UseWindowsAuthentication) }		
# (Test-SQLDatabase -Server $BDserver -Database $BD -Username $BDlogin -Password $BDpass) }	
	
}

# Прерыватель процесса, если была ошибка
Function Breaker ($Breaker) {
	if ($error.count -gt 0)  {
		Write-host "`n ----------- Count error:" $error.count 
		Write-host "`n ---------- WTF???"
        #Write-host $error -ForegroundColor red -BackgroundColor black
        #$error
		
        #$VersionBuild + " - FAILED"| Out-File .\VersionBuild_$ProjectType.txt  -Append
		read-host "`n push ENTER for exit"	
		exit(1)	
	}
}

# Функция ожидания нажатия клавиши
Function PauseKey {
    ""
	$replyKey='Y'
	do {$reply = Read-Host -Prompt «Continue?[$ReplyKey]»}
	while ($reply -ne $ReplyKey)
} 


#Сборка проекта
function CompileRelease {
	param (
		$PathProjectSVN
    )

    "Update to HEAD revision"
    svn up $PathProjectSVN

    "`tGenerate assembly files"
    wscript "$PathProjectSVN\_scripts\PostUpdate.js" null 0 0 null $PathProjectSVN
           
    "`tBuilding references libs"
    $MSBuild = & "$PathProjectSVN\_scripts\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe 
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,Platform="Any CPU" "$PathProjectSVN\Lzma\Lzma.sln"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,Platform="Any CPU" "$PathProjectSVN\Controls\Controls.sln"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,Platform="Any CPU" "$PathProjectSVN\PopUpWindows\PopupWindows.sln"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release,/p:Platform="Any CPU" "$PathProjectSVN\CertificateServiceV2\SabCertService.sln"

    "`tBuilding secondary projects"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release /p:Platform="Any CPU" "$PathProjectSVN\UpdateManager\UpdateManager.sln"

    "`tBuilding main solutions"
    & $MSBuild /m /consoleloggerparameters:ErrorsOnly /nologo /p:Configuration=Release /p:Platform="Any CPU" "$PathProjectSVN\Sima.sln"

}

## остановка/запуск слежб на сервере
function UMServiseAction {
	param (
		[string] $Servise,	
		[string] $ServisePath,		
		[Array]  $ServiseName,		
		[string] $ServiseStatus		
	)
	
	[string]$WaitForIt = ""
	[string]$Verb = ""
	[string]$Result = "FAILED"
	
	#Write-host "$Servise"	
	foreach ( $item in $ServiseName )  {
		if( $item ) {
			$ServiseName = $item
			$svc = (get-service -computername $ServisePath -name $ServiseName)
			#Write-host "$ServiseName just now $($svc.status)"

			#Начинем работать когда запрос сервиса отлисчается от его текущего статуса
			if ($svc.status -ne $ServiseStatus) {
				Switch ($ServiseStatus)  {
					'Running'  {
						#Write-host "Starting $ServiseName..."
						$Verb = "Start"
						$WaitForIt = 'Running'
						$svc.Start()
					}
				
					'Stopped'  {
						#Write-host "Stopping $ServiseName..."
						$Verb = "stop"
						$WaitForIt = 'Stopped'
						$svc.Stop()
					}		
				}
			} 
			else {Write-host "$ServiseName is $($svc.status).  Taking no action."}

			if ($WaitForIt -ne "")  {
				Try  { #ожидаем отклика после смены статуса сервиса
				  $svc.WaitForStatus($WaitForIt,'00:02:00')
				} 
				Catch  {
					Write-host "After waiting for 2 minutes, $ServiseName failed to $Verb."
				}
				$svc = (get-service -computername $ServisePath -name $ServiseName)
				if ($svc.status -eq $WaitForIt) {$Result = 'SUCCESS'}
				#Write-host "$Result`: $ServiseName on $ServisePath is $($svc.status) `n"
				#Write-host "$ServiseName is $($svc.status) `n"
			}
		}	
	}
}



## копировать с повторениями
function CopyTryHard {
	param (
		[string] $CopyTo,
		[string] $CopyFrom		
	)
	#Write-host "From: $CopyFrom"
	#Write-host "To  : $CopyTo"
	$Try= 0
	
	do { #копируем до тех пор, пока не прорвемся через блок файлов, повторять $TryCount раз			
		$TryCount = 10
		$cc = 1
		$ororo=0
		Get-ChildItem $CopyFrom | foreach ($_) {
		   #"COPY: " + $_.name  
		   #Write-host "$cc $_"	
		   
			try {			
				copy-item $_.fullname  -destination $CopyTo -recurse 
			}
			Catch  {
				$ororo++
				$ororoTest = $error[0]#.Exception
				#Write-host $ororoTest  -ForegroundColor red -BackgroundColor black	 			
			}
		   $cc++
		} 
		#""
		$Try++

		IF ($Try -eq $TryCount) {
			"`n Try hard: $Try"	
			Breaker
		}
	}
	while  ($ororo -gt 0 )
	
	if ($Try -gt 1) {
		#"Try hard: $Try `n"	
		Write-host "Try hard: $Try `n"  -ForegroundColor red -BackgroundColor black		
	}
}

# Получаем список скриптов обновления
function ScriptsSQLEView {
	param (
		 $repository,
         $revision_from,
         $revision_to         			
	)
	
	# debug
	#$revision_from = 24180 
    #$revision_to =   24190

	$repository = $repository + "\SIMADATABASE"	
    SVN up $repository | Out-Null

    $ScriptsList = @()
    $svn = "$revision_from" + ":" + "$revision_to"  

    # вытаскиваем список скриптов из репозитория
    SVN diff --summarize -r $svn $repository | Where-Object {$_[0] -notlike "D"} | ForEach ($_) { 
        $SVNDiff = $_.replace('      ','').Split(" ",2)
        IF($SVNDiff[1] -like "*.sql") {
            $ScriptsList += ($SVNDiff[1])              
        }
    }
	
	# проверяем, если в сборке были изменения на Permissions, добавляем в список CreateRootGroup
	if ($ScriptsList | Where-Object { $_ -like "*Queries\Permissions*"}  ) {
		$ScriptsList += ("$repository\Utils\CreateRootGroup.sql")
	}
	
    $count = 0
    $Array = @()

	# Чтобы распарсить скрипты на блоки, приходится использовать физические пути
	Set-Location -Path $repository
    $ScriptsList | foreach ($_) {
        $count++
        $PathList =  Get-ChildItem -File $_              # Превращаем в объекты пути
        $Path =      Split-Path -Path $PathList.FullName # Получаем полный путь без конечного файла
        $Name =      $PathList.Name                      # конечный файл        
        $PathGroup = $Path.Replace("$repository\", "")   # отрезаем начальный путь
        
        # debug  Очередность заполнения
        #$Path       
        #$PathGroup
        #$Name
        #$repository	

        # Задаем сортировку в зависимости от приоритета  
        $Sort = 100
        Switch ($PathGroup)  {
			'Stored Procedures\System' 			{$Sort = 1 }
		    'Create Scripts' 					{$Sort = 2 }
		    'Create Scripts\223' 				{$Sort = 3 }
		    'Create Scripts\Analytics' 			{$Sort = 3 }
            'Views' 							{$Sort = 4 }
            'Queries\Parameters' 				{$Sort = 5 }
            'Queries\Parameters\SetParametrs' 	{$Sort = 6 }
            'Queries\_RunOnce' 					{$Sort = 7 }
            'Queries\_RunOnce\223' 				{$Sort = 7 }
            'Queries\FillingOfDirectories' 		{$Sort = 8 }
			'Utils' 							{$Sort = 101 }			
        }
        $Array += [PSCustomObject]@{Number=$count; Path=$Path; PathGroup=$PathGroup; Name=$Name; Sort =$Sort}          
   }

    "`n--- Interpretation SQL"
    # Пересоздаем массив с сортировкой. Общий список всех скриптов
    $Array = @($Array | Sort-Object -property Sort,PathGroup,Name )
    $Array | Format-Table -a PathGroup,Name 
    "Count script: " + $Array.Count
	

	
	##### 
	## Создаем апдейт лист на БД
	#####
	
	$ArrayList = @()
    $Array_RunOnce = @()
    $Array_RunOnceNew = @()
	
    # Вычещаем лишнее
    # Получаем список 223. Когда-нибудь, все скрипты будут "красивыми" и этот блог будет не нужен.
    $Array223 = @($Array | Where-Object { $_.PathGroup -like "*223*" -or $_.Name -like "*223*"} )
   
    # Для 44, пересоздаем итоговый массив без строк 223    
    if ($SectionProject -eq "44") {        
        $ArrayList =   @($Array | Where-Object { !($_.PathGroup -like "*223*" -or $_.Name -like "*223*" )} ) 
    } else {$ArrayList = $Array}

    # -------------------------------------------
    # Проверяем установленные на сервере скрипты _RunOnce. Исключаем из списка установленные ранее 
    $Array_RunOnce = @($ArrayList | Where-Object { $_.PathGroup -like    "*_RunOnce*"} )   
    $ArrayList =     @($ArrayList | Where-Object { $_.PathGroup -notlike "*_RunOnce*"} )   
 
    #$Array_RunOnce | ft -a PathGroup,Name 
    $Array_RunOnce  | foreach ($_) { 
        $Path = $_.Path
        $Name = $_.Name
        $Hash = Get-FileHash "$Path\$Name"  -Algorithm MD5 
        
        $ScriptNameRunOnceCase = Invoke-Sqlcmd -Query "SELECT top 1 ScriptName 
                                                        FROM _RunOnceScriptsApplied 
                                                        WHERE Hash='$($Hash.Hash)' and ScriptName = '$($Name)'
                                                        --WHERE ScriptName = '$($Name)' 
                                                        ORDER BY TS DESC" -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass
        
        # Выходим из конекта SQLservera, чтобы продолжить run скрипта. Да, такое решение надо придать анафеме, но пока так
        #cd c:\
        
        ## Если хеши не совпадают, значит, ранванс надо накатить, и добавляем его в список
        if($ScriptNameRunOnceCase.Length -eq 0) {
            $Array_RunOnceNew += [PSCustomObject]@{Number=$_.Number; Path=$_.Path; PathGroup=$_.PathGroup; Name=$_.Name; Sort =$_.Sort; Hash=$Hash.Hash}  
            $ArrayList        += [PSCustomObject]@{Number=$_.Number; Path=$_.Path; PathGroup=$_.PathGroup; Name=$_.Name; Sort =$_.Sort}   
        }    
    }

    # лист 223
    if ($SectionProject -eq "44" -and $Array223.count -gt "0" ) {
        "`n--- List 223 del "   	
        $Array223 | Format-Table -a PathGroup,Name 
        "Count: " + $Array223.Count
    }
	
    # лист RunOnce скриптов
    if ($Array_RunOnce.count -gt 0 ) {
        "`n--- List RunOnce "   	
        $Array_RunOnce | Format-Table -a PathGroup,Name 
        "Count: " + $Array_RunOnce.Count
    }
	
	if ($Array_RunOnceNew.count -gt 0 ) {
        "`n--- List RunOnce New"   	
        $Array_RunOnceNew | Format-Table -a PathGroup,Name,Hash
        "Count: " + $Array_RunOnceNew.Count
    }
	
    "`n--- List RUN"
    # Пересоздаем массив с сортировкой. Общий список всех скриптов
    $ArrayList = @($ArrayList | Sort-Object -property Sort,Path,name,Number ) 
    # перестраиваем номирацию строк
    $count=0
    $ArrayList | foreach ($_) {
        $count++
        $i = $ArrayList.IndexOF($_)   
        $ArrayList[$i].Number = $count
    } 
    # !!!!!!!!!!!!!!!!  Выводим на экран финальный список скрипов
    #$ArrayList | Format-Table -a Number,PathGroup,Name 
    "Count RUN list: " + $ArrayList.Count   

    ## Создаем глобальную переменную  итогового списока скриптов
	New-Variable -Name SQLList    -Value $Array     -Scope Global -Force
    New-Variable -Name SQLListRUN -Value $ArrayList -Scope Global -Force
		
}



Function ScriptsSQLList  {
	param ($SQLList,
           $SQLListRUN
   )
   
    # Создаем папку, куда будем пихать логи и ошибки
    if ($SQLList.count -ne 0) {   
		$folder = $ConfigJson.Version.ListNEW
        $ScriptsList = "$ScriptsList\$ProjectType\$folder\Scripts"
        New-Item -Path $ScriptsList -ItemType Directory -Force | Out-Null 
        
        $SQLList | foreach {
            $PathGroup = $_.PathGroup
            $Name = $_.Name        
            "$PathGroup\$Name"         
        } | Set-Content "$ScriptsList\1.List.txt"

        $SQLListRUN | foreach {
            $PathGroup = $_.PathGroup
            $Name = $_.Name        
            "$PathGroup\$Name"         
        } | Set-Content "$ScriptsList\2.ListRUN.txt"
    }   
	
}	

Function ScriptsSQLRundel  {
    param ($repository,
           $ClientBuild,
           $List,
		   $ListRUN 			
    ) 


	$repository = $repository + "\SIMADATABASE"
    $Failed = ""
    $Error_list = @()
    $ErrorCount = 0

    $ListRUN  | foreach ($_) { 
        $Number = $_.Number        
        $Path = $_.Path
        $PathGroup = $_.PathGroup
        $Name = $_.Name

        $PathScript = "$repository\$PathGroup\$Name"
        $NScriptEcho = "$Number" +"-"+ $ListRUN.Count + " : "+ "$PathGroup" + "\$Name"       
		
		$NScriptEcho
        $error.Clear()
        
        # Накатываем скрипт в БД
        Invoke-Sqlcmd -InputFile $PathScript -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass -ErrorAction SilentlyContinue   -ErrorVariable Failed
        
        # записываем в БД запущенные RunOnce-ы
        if($Path -like '*RunOnce*' -and !($error)) {
            $Hash = Get-FileHash $PathScript  -Algorithm MD5 
            #$Hash.Hash
            Invoke-Sqlcmd -Query "INSERT INTO _RunOnceScriptsApplied (ScriptName,Hash) VALUES ('$Name', '$($Hash.Hash)' )" -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass            
        }

        # если есть ошибки, выводим на экран и собираем данные в массив
        if($error) {          
            Write-host "$NScriptEcho - ERROR" -ForegroundColor red -BackgroundColor black
            # берем последнего автора кто трогал скрипт
            if(!($ProjectType -eq "Prod")) {
                $SVNSQL = ([xml](svn log  $PathScript --xml)).log.logentry 
			    $SVNSQLAuthor = $SVNSQL[0].author
            }
              
            $Error_list += [PSCustomObject]@{Name="$PathGroup\$Name"; SVNSQLAuthor=$SVNSQLAuthor; Failed=$Failed[0] }    
            $ErrorCount++
            $error.Clear()

        }       
        # Выходим из конекта SQLservera, чтобы продолжить run скрипта. Да, такое решение надо придать анафеме, но пока так
        #cd c:\
    }

    $Error_list | Format-list  SVNSQLAuthor, Name, Failed
    "`nCount of errors:  $ErrorCount `n"
    
    # Записываем все ошибки в лог
    $Error_list | foreach {
        "(" + $_.SVNSQLAuthor+") --- " + $_.Name
        $_.Failed 
        "`n"
    } | Set-Content "$ClientBuild\Error.txt"


 
}


Function ScriptsSQLRun  {
    param ($repository,
		   $ListRUNPath 			
    ) 
	
	#$repository = $repository + "\SIMADATABASE"
	#$ListRUN = Get-Content "$ListRUNPath\Scripts\2.ListRUN.txt"
	$ListRUN = Get-Content $ListRUNPath

    $Error_list = @()
    $ErrorCount = 0
	$count=0

    $ListRUN  | foreach ($_) { 
		$count++
		$Number = $count
		$PathList =  Get-ChildItem -File "$repository\$_"  # Превращаем в объекты пути
        $Path =      Split-Path -Path $PathList.FullName # Получаем полный путь без конечного файла
        $Name =      $PathList.Name                      # конечный файл        
        $PathGroup = $Path.Replace("$repository\", "")   # отрезаем начальный путь
		

        $PathScript = "$repository\$PathGroup\$Name"
        $NScriptEcho = "$Number" +"-"+ $ListRUN.Count + " : "+ "$PathGroup" + "\$Name"       
		
		$NScriptEcho
        $error.Clear()
		$Failed=""
        
        # Накатываем скрипт в БД
        Invoke-Sqlcmd -InputFile $PathScript -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass #-ErrorAction SilentlyContinue
        
        # записываем в БД запущенные RunOnce-ы
        if($Path -like '*RunOnce*' -and $error[0] -ne "") {
            $Hash = Get-FileHash $PathScript  -Algorithm MD5 
            #$Hash.Hash
            Invoke-Sqlcmd -Query "INSERT INTO _RunOnceScriptsApplied (ScriptName,Hash) VALUES ('$Name', '$($Hash.Hash)' )" -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass            
        }

        # если есть ошибки, выводим на экран и собираем данные в массив
        if($error[0]) {          
            Write-host "$NScriptEcho - ERROR" -ForegroundColor red -BackgroundColor black
            # берем последнего автора кто трогал скрипт
            if(!($ProjectType -eq "Prod")) {
                $SVNSQL = ([xml](svn log  $PathScript --xml)).log.logentry 
			    $SVNSQLAuthor = $SVNSQL[0].author
            }
              
            $Error_list += [PSCustomObject]@{Name="$PathGroup\$Name"; SVNSQLAuthor=$SVNSQLAuthor; Failed=$error[0] }    
            $ErrorCount++
            #$error.Clear()

        }      
        # Выходим из конекта SQLservera, чтобы продолжить run скрипта. Да, такое решение надо придать анафеме, но пока так
        #cd c:\
    }

    $Error_list | Format-list  SVNSQLAuthor, Name, Failed
    "`nCount of errors:  $ErrorCount"
    
    # Записываем все ошибки в лог
    $Error_list | foreach {
        "(" + $_.SVNSQLAuthor+") --- " + $_.Name
        $_.Failed 
        "`n"
    } | Set-Content "$ListRUNPath\Error.txt"

	# "Умная" остановка всего модуля, если запущено в CI
	IF ($ErrorCount -gt 0) {
		IF ($CI -eq "CI") {		
			exit(1)
		} else {
			PauseKey
		}
	}
}

function ConvertText {
	param($textin)

	$count=0
	$textout = '@("'
	$textin | foreach {
		$count++
		
		if($count -ne $textin.count) {
			$point = '", "'
		} else {$point =  '")'}
		
		$textout = $textout  + $_ +  $point
		
	}	

	$textout

}

Function CreatedConfig {
	param($ClientBuild)

	$File="$ClientBuild\Config.ps1"

	"# --------------" 							| Out-File $File
	"$"+"SectionProject = '$SectionProject'"  	| Out-File $File -Append 
	"$"+"Project     = '$Project'" 				| Out-File $File -Append 
	"$"+"ProjectType = '$ProjectType'" 			| Out-File $File -Append 

	"$"+"GS  = '$GS'" 							| Out-File $File -Append 
	"$"+"TS  = '$TS'" 							| Out-File $File -Append 
	"$"+"Web = '$Web'" 							| Out-File $File -Append 

	"$"+"DBURL   = '$DBURL'" 					| Out-File $File -Append 
	"$"+"DBName  = '$DBName'" 					| Out-File $File -Append 
	"$"+"DBlogin = '$DBlogin'" 					| Out-File $File -Append 
	"$"+"DBpass  = '$DBpass'" 					| Out-File $File -Append 


	$PathListT = ConvertText -textin $PathList
	$GSPathListT = ConvertText -textin $GSPathList
	$TSPathListT = ConvertText -textin $TSPathList
	$WEBPathListT = ConvertText -textin $WEBPathList
	
	$GSServiseNameListT = ConvertText -textin $GSServiseNameList
	$TSServiseNameListT = ConvertText -textin $TSServiseNameList


	"$"+"PathList    = $PathListT" 					| Out-File $File -Append 
	"$"+"GSPathList  = $GSPathListT" 				| Out-File $File -Append 
	"$"+"TSPathList  = $TSPathListT" 				| Out-File $File -Append 
	"$"+"WEBPathList = $WEBPathListT" 				| Out-File $File -Append 
	"$"+"GSServiseNameList = $GSServiseNameListT" 	| Out-File $File -Append 
	"$"+"TSServiseNameList = $TSServiseNameListT" 	| Out-File $File -Append 
		

}



