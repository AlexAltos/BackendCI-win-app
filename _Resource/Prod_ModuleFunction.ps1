# Функция ожидания нажатия любой клавиши
Function Pause ($Msg) {
    if ($psise) {
        # Если выполняется в ISE       
        Add-Type -assem System.Windows.Forms
        [void][Windows.Forms.MessageBox]::Show("$Msg")
	} else  {
		# Если выполняется в ConsoleHost
		Write-Host "$Msg"
		$host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown') | Out-Null
	}
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


Function Breaker ($Breaker) {
	if ($error.count -gt 0)  {
		Write-host "`n ----------- Count error:" $error.count 
		Write-host "`n ---------- WTF??? can't go on!"
        Write-host $error -ForegroundColor red -BackgroundColor black
        $error
		
        $VersionBuild + " - FAILED"| Out-File .\VersionBuild_$ProjectType.txt  -Append
		read-host "`n push ENTER for exit"	
		exit	
	}
}

# Функция ожидания нажатия клавиши
Function PauseKey {
    ""
	$replyKey='Y'
	do {$reply = Read-Host -Prompt «Continue?[$ReplyKey]»}
	while ($reply -ne $ReplyKey)
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
		   Write-host "$cc $_"	
		   
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

Function ScriptsSQLListRun  {
    param ($repository) 
	

	<#
	$repository = (Get-Culture).TextInfo.ToTitleCase($repository.ToLower()) #Вписать символ диска всегда в ВЕРХНЕМ регитре
	IF( $repository.Substring($repository.Length - 1) -eq "\" ) {# проверяем последний символ в строке, если он \ то удаляем
		$repository = $repository.Substring(0 , $repository.length - 1)
	}
	#>
	
	#$repository = $repository + "\SIMADATABASE"
	#$APPFolder = Get-ChildItem $repository | Where-Object {$_.mode -match "d"}  | Sort-Object LastWriteTime | Select-Object -Last 1
	#$repository = "$repository\$APPFolder\Scripts"
	$ListRUN = Get-Content "$repository\2.ListRUN.txt"
	$ListRUN
	
	# -------------------------------------------
    # Проверяем установленные на сервере скрипты _RunOnce. Исключаем из списка установленные ранее 
    #$Array_RunOnce = @($ListRUN | Where-Object { $_ -like    "*_RunOnce*"} )   
    #$ListRUN =     @($ListRUN | Where-Object { $_ -notlike "*_RunOnce*"} )   
	
	$ListRUN  | foreach ($_) { 
		if($_ -like "*_RunOnce*") {
			$Array_RunOnce += @("`n"+$_)		
		} else {
			$ListRUNn += @("`n"+$_)
		}
	}
	
 
    "--"+$Array_RunOnce 
	"-------------------"
	"22"+$ListRUNn
	
	
    $Array_RunOnce  | foreach ($_) { 
			"--"+$_
			"22"+"$repository\$_"
		$PathList =  Get-ChildItem  "$repository\$_"     # Превращаем в объекты пути
        $Path =      Split-Path -Path $PathList.FullName # Получаем полный путь без конечного файла
        $Name =      $PathList.Name                      # конечный файл   
		
        $Hash = Get-FileHash "$Path\$Name"  -Algorithm MD5 
        $Hash
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
            $ListRUN 		  += [PSCustomObject]@{Number=$_.Number; Path=$_.Path; PathGroup=$_.PathGroup; Name=$_.Name; Sort =$_.Sort}   
        }    
    }
	
	
	# Считываем файл очереди 
	$ListRUN

	pause
	
    $Error_list = @()
    $ErrorCount = 0
	$count=0

    $ListRUN  | foreach ($_) { 
		$count++
		$Number = $count		
		$PathList =  Get-ChildItem  "$repository\$_"              # Превращаем в объекты пути
        $Path =      Split-Path -Path $PathList.FullName # Получаем полный путь без конечного файла
        $Name =      $PathList.Name                      # конечный файл        
		$PathGroup = $Path.Replace("$repository\", "")   # отрезаем начальный путь		
		
<# 		
		$repository.getType().Fullname
		$Path.getType().Fullname
"11"	

"-- " + $PathList	
"55 " + $repository
#"1- " + $Path    
#"2- " + $Name   		
"3- " + $PathGroup 

"11" #>		
		
        $PathScript = "$repository\$PathGroup\$Name"
        $NScriptEcho = "$Number" +"-"+ $ListRUN.Count + " : "+ "$PathGroup" + "\$Name"       
		
		$NScriptEcho
        #$error.Clear()
		$Failed=""
        
        # Накатываем скрипт в БД
        #Invoke-Sqlcmd -InputFile $PathScript -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass -ErrorAction SilentlyContinue   -ErrorVariable Failed
        
        # записываем в БД запущенные RunOnce-ы
        if($Path -like '*RunOnce*' -and $Failed -ne "") {
            $Hash = Get-FileHash $PathScript  -Algorithm MD5 
            #$Hash.Hash
            Invoke-Sqlcmd -Query "INSERT INTO _RunOnceScriptsApplied (ScriptName,Hash) VALUES ('$Name', '$($Hash.Hash)' )" -ServerInstance $DB -Database $DBName -U $DBlogin -Password $DBpass            
        }

        # если есть ошибки, выводим на экран и собираем данные в массив
        if($Failed) {          
            Write-host "$NScriptEcho - ERROR" -ForegroundColor red -BackgroundColor black            
              
            $Error_list += [PSCustomObject]@{Name="$PathGroup\$Name"; Failed=$Failed[0] }    
            $ErrorCount++
            #$error.Clear()

            # копируем вбок для анализа
            $PathCopy = "$ListPath\$PathGroup"
            if(!(Test-Path $PathCopy -ErrorAction SilentlyContinue))  {
                New-Item -Path $PathCopy -ItemType Directory -Force | Out-Null               
            } 
			copy-item $PathScript -destination $PathCopy -recurse  
        }      
        # Выходим из конекта SQLservera, чтобы продолжить run скрипта. Да, такое решение надо придать анафеме, но пока так
        cd c:\
		
		#Breaker
    }

    $Error_list | Format-list  SVNSQLAuthor, Name, Failed
    "`nCount of errors:  $ErrorCount"
    
    # Записываем все ошибки в лог
    $Error_list | foreach {
        "(" + $_.SVNSQLAuthor+") --- " + $_.Name
        $_.Failed 
        "`n"
    } | Set-Content "$ListPath\Error.txt"


 
}

Function SQLRun {
	param ($repository) 
	
	$PathFull = $repository

    $ErrorCount = 0
    $Date = Get-Date -Format u	

    $Array = @()
    $Array223 = @()
    $ArrayList = @()
    $Array_RunOnce = @()
	$Array_RunOnceNew = @()
	
    # Берем последнию папку скриптов
    #$FolderSQL = Get-ChildItem $PathSQL | Where-Object {$_.mode -match "d"} | Sort-Object LastWriteTime | Select-Object -Last 1 # Last first
    #$PathFull = "$PathSQL\$FolderSQL"
	$PathFull = "$repository"
	$PathSQLError = "$repository\ScriptsError"

    # Получаем список скриптов, для дальнейшей обработки
    Set-Location $PathFull #быдло решение, но пока пусть так
    Get-ChildItem -recurse -Include *.sql | foreach ($_) {
        $Name = $_.name                          # конечный файл по пути
        $Path = Split-Path -Path $_.Fullname     # Получаем полный путь без конечного файла
        $Path = $Path.Replace("$PathFull", "")   # отрезаем начальный путь
        
        if($Path.length -gt 0) { #если файлы не в нулевом каталоге
            $Path = $Path.Substring(1, $Path.length - 1)  # удаляем первый символ "\"          
        }  Else { $Path = "" }

        # Задаем сортировку в зависимости от приоритета  
        $Sort = 100
        Switch ($Path)  {
			'Stored Procedures\System' 			{$Sort = 1 }
		    'Create Scripts' 					{$Sort = 2 }
		    'Create Scripts\223' 				{$Sort = 3 }
            'Views' 							{$Sort = 4 }
            'Queries\Parameters' 				{$Sort = 5 }
            'Queries\Parameters\SetParametrs' 	{$Sort = 6 }
            'Queries\_RunOnce' 					{$Sort = 7 }
            'Queries\FillingOfDirectories' 		{$Sort = 8 }
			'Utils' 							{$Sort = 101 }
			
        }
        $Array += [PSCustomObject]@{Sort=$Sort; Path=$Path; Name =$Name}   
    }

    # -------------------------------------------
    # Пересоздаем массив с сортировкой. Общий список всех скриптов
    $Array = @($Array | Sort-Object -property Sort,Path,name )


    # -------------------------------------------
    # Вычещаем лишнее
    # Удаляем скрипты 223. Когда-нибудь, все скрипты будут "красивыми" и этот блог будет не нужен.
    $Array223 = @($Array | Where-Object { $_.Path -like "*223*" -or $_.Name -like "*223*"} )
   
    # если 44, пересоздаем итоговый массив без строк 223
    $ArrayList = @()
    if ($SectionProject -eq "44") {        
        $ArrayList =   @($Array | Where-Object { !($_.Path -like "*223*" -or $_.Name -like "*223*" )} ) 
    } else {$ArrayList = $Array}


    # -------------------------------------------
    # Проверяем установленные на сервере скрипты _RunOnce. Исключаем из списка установленные ранее
    $Array_RunOnce = @($ArrayList | Where-Object { $_.Path -like    "*_RunOnce*"} )   
    $ArrayList =     @($ArrayList | Where-Object { $_.Path -notlike "*_RunOnce*"} )   

    $Array_RunOnce  | foreach ($_) { 
        $Path = $_.Path
        $Name = $_.Name
        $Hash = Get-FileHash "$PathFull\$Path\$Name"  -Algorithm MD5 

        $ScriptNameRunOnceCase = Invoke-Sqlcmd -Query "SELECT top 1 ScriptName 
                                                       FROM _RunOnceScriptsApplied 
                                                       WHERE Hash='$($Hash.Hash)' and ScriptName = '$($Name)'
                                                       --WHERE ScriptName = '$($Name)' 
                                                       ORDER BY TS DESC" -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass
        
        # Выходим из конекта SQLservera, чтобы продолжить run скрипта. Да, такое решение надо придать анафеме, но пока так
        cd c:\
        if($ScriptNameRunOnceCase.Length -eq 0) {
            $Array_RunOnceNew += [PSCustomObject]@{Sort=$_.Sort; Path=$_.Path; Name =$_.Name; Hash=$Hash.Hash}  
            $ArrayList        += [PSCustomObject]@{Sort=$_.Sort; Path=$_.Path; Name =$_.Name}   
        }    
    }

    # -------------------------------------------

    "Count Scripts: " + $Array.Count
	
    # лист всех скриптов
    # "`n--- All Scripts"
    # $Array  | ft -a   

    # лист 223
    if ($SectionProject -eq "44" -and $Array223.count -gt "0" ) {
        "`n--- List 223 del "   	
        $Array223 | ft -a
        "Count Scripts: " + $Array223.Count
    }
	
    # лист RunOnce скриптов
    if ($Array_RunOnce.count -gt "0" ) {
        "`n--- List RunOnce "   	
        $Array_RunOnce | ft -a
        "Count Scripts: " + $Array_RunOnce.Count
    }
	
	if ($Array_RunOnceNew.count -gt "0" ) {
        "`n--- List RunOnce New"   	
        $Array_RunOnceNew | ft -a
        "Count Scripts: " + $Array_RunOnceNew.Count
    }
	
    # "`n--- List RunOnce "
    # $Array_RunOnce | ft -a

    # "`n--- List RunOnce New"
    # $Array_RunOnceNew | ft -a

    "`n--- List RUN"
    # Пересоздаем массив с сортировкой. Общий список всех скриптов
    $ArrayList = @($ArrayList | Sort-Object -property Sort,Path,name )
    # $ArrayList | ft -a
    "Count Scripts: " + $ArrayList.Count

    # -------------------------------------------
    # -------------------------------------------

    "`n----SQL Run---"
	#$PathSQLErrorLog = "$PathSQLError\history.log"	
	$NScript=1
	$ArrayListCount = $ArrayList.count
	
    $ArrayList  | foreach ($_) {         
        if ($ArrayList.count -gt 1) {
            $i = $ArrayList.IndexOF($_)                        
            $Path = $ArrayList.Path[$i]
            $Name = $ArrayList.Name[$i]
        } else {
            $Path = $ArrayList.Path
            $Name = $ArrayList.Name
        }
		
      
        if ($Path.Length -eq 0) {$Triger = ""} else {$Triger = "\"}                     
        $PathItem = "$Path" + "$Triger" + "$Name"        
		$NScriptEcho = "$NScript-$ArrayListCount : $PathItem"
		
		$NScriptEcho
        $error.Clear()

        #break
              
        Invoke-Sqlcmd -InputFile "$PathFull\$PathItem" -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass

        # записываем в БД запущенные RunOnce-ы
        if($Path -like '*RunOnce*' -and !($error)) {
            $Hash = Get-FileHash "$PathFull\$Path\$Name"  -Algorithm MD5 | Select Hash
            #$Hash = $Hash.Hash
            Invoke-Sqlcmd -Query "INSERT INTO _RunOnceScriptsApplied (ScriptName,Hash) VALUES ('$Name', '$($Hash.Hash)' )" -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass
        }
    
        # Если при выполнении скрипта, была ошибка. выводим это на экран и записываем в лог
        if($error) {          
            Write-host $NScriptEcho  -ForegroundColor red -BackgroundColor black       
            $ErrorCount++

            # Выходим из конекта SQLservera, чтобы продолжить run скрипта. Да, такое решение надо придать анафеме, но пока так
            cd c:\
		
            $PathCopy = "$PathSQLError\$Path"
            if(!(Test-Path $PathCopy -ErrorAction SilentlyContinue))  {
                New-Item -Path $PathCopy -ItemType Directory -Force | Out-Null               
            } 
			copy-item "$PathFull\$PathItem" -destination $PathCopy -recurse  
			
			$PathSQLErrorLog = "$PathSQLError\history.log"	
			echo "-->" >> $PathSQLErrorLog
			echo "--> --- $PathItem" >> $PathSQLErrorLog
            echo "$error `n" >> $PathSQLErrorLog
        }
		$NScript++
    }

    Write-host "`n Count of errors:  $ErrorCount"
	if ($ErrorCount) {	
		PauseKey
	}
	
    #cd c:\

}
