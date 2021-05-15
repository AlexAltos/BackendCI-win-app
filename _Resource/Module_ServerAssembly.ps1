## Module_ServerAssembly.ps1
## Модули выполнения сборки и обновления




Function LoadPreparation  {
	
	# Делаем заголовок консоли
	$host.ui.RawUI.WindowTitle = "Update " + $SectionProject +" "+  $Project +" "+ $ProjectType +": " + $ConfigJson.Version.ListNEW
	

	"====================== UpdateMachine--Start update AIS ================" 
	"Project: $SectionProject, $Project, $ProjectType"
	"Branch:  $PathProjectSVN"

	#Берем гибриды-списки переменные из Config_Test.ps1	
	<#
	$PathList = @($PathGS, $PathTS, $PathWEB)
	$GSPathList = @($PathGS)
	$TSPathList = @($PathTS)

	$GSServiseNameList = @($GSServiseName)
	$TSServiseNameList = @($TSServiseName)	
	#>

	IF ($ProjectType -ne "Prod") {
		# Проверка на присутсвие	
		$echo = @()	
		$PathList  | foreach ($_) { 		
			$CheckerPathECHO = UMChecker -TestPath $_	
			$echo += [PSCustomObject]@{parent="Path"; target=$CheckerPathECHO[0]; result=$CheckerPathECHO[1]; errorr=$CheckerPathECHO[2]}  
		}	
			
		# GeneralServer"
		$GSServiseNameList  | foreach ($_) { 
			$CheckerPathECHO = UMChecker -ServisePath $ConfigJson.GS.IP -ServiseName $_ 	
			$echo += [PSCustomObject]@{parent="GS";target=$CheckerPathECHO[0]; result=$CheckerPathECHO[1]; errorr=$CheckerPathECHO[2]}  
		}
		
		# TransportServer"
		$TSServiseNameList  | foreach ($_) { 
			$CheckerPathECHO = UMChecker -ServisePath $ConfigJson.TS.IP -ServiseName $_ 	
			$echo += [PSCustomObject]@{parent="TS";target=$CheckerPathECHO[0]; result=$CheckerPathECHO[1]; errorr=$CheckerPathECHO[2]}  
		}
	}
   

   

    # SQL DataBase"	
	$CheckerPathECHO = Test-SQLDatabase -Server $DBURL -Database $DBName -Username $DBLogin -Password $DBPass
	$echo += [PSCustomObject]@{parent="DataBase";target=$CheckerPathECHO[0]; result=$CheckerPathECHO[1]; errorr=$CheckerPathECHO[2]}  
	
	
	#Вывод результата основных путей на экран
	$echo | Format-Table -a parent,target, result
	
	#наркоманский способ суммирования результатов, и остановка если были ошибки
	$echoerrorr=0
	$echo.errorr  | foreach ($_) { 
		if ($_ -gt 0) { $echoerrorr++}
	}
	
	if ($echoerrorr -gt 0) {
		Write-host "`n----------- Not all steps ready"  -ForegroundColor red -BackgroundColor black   
		pause	"press button..."
		exit
	}
	
	"`n-- Version Current"
	$ConfigJson.Version.ListCurrent
	
	"`n-- Version Next "  
	$ConfigJson.Version.ListNEW
	

	# визуальный чек статус с Compile Release проекта
    "`n-- Branch Status"
    IF ($SVN_Minor -ne $SVN_MinorBranch ) {
        Write-host "`t Branch Compile is NEED" -ForegroundColor red -BackgroundColor black
    } else {
        Write-host "`t Branch Compile is OK" -ForegroundColor green      
    }
	
	# проверка на необходимость обновления
    IF ($SVN_Minor -eq $DB_Minor) { 
        Write-host "`t Update is not required" -ForegroundColor green 
    }
	
    ## Смотрим кол-во скриптов в сборке      
    ScriptsSQLEView -repository $PathProjectSVN -revision_from $DB_Minor -revision_to $SVN_Minor

	#Остановить если были ошибки
	Breaker

	##################################################
	## Если не CI, то спросить, о продолжении
	##################################################
	IF (!($CI -eq "CI")) { PauseKey}
	
	
	#!!!!!!!!! Запускаем мейн билд всего проекта, если то требуется
    IF ($SVN_Minor -ne $SVN_MinorBranch) {
        CompileRelease -PathProjectSVN $PathProjectSVN
    }
	
	#Создаем список скриптов для дальнейшей работы
	ScriptsSQLList -SQLList $SQLList -SQLListRUN $SQLListRUN
}



# Собираем все артефакты после компиля проекта
Function CollectArtifacts  {
	param (
		$FromPath,	
		$CompileArtifacts,	
		$ClearBinaries
	)

    #------------- Собираем компоненты #-------------
    "`nPhase: Collect Compile Artifacts from Branch: $FromPath "   
	
    ## Зачищаем имеющиеся файлы
    "`tClear binaries"       
	if(Test-Path $ClearBinaries ) {Remove-Item $ClearBinaries -Force -Recurse  }
	New-Item -Path $CompileArtifacts  -ItemType Directory -Force | Out-Null 
    Breaker
    
	# плагины. 
	if($ConfigExceptionsProject -ne "SAG") {
		## Копируем  оператора
		"`tCopy plugins" 
		$CopyFrom = "$FromPath\Plugins"
		$CopyTo   = "$CompileArtifacts\Plugins\operator" 
			
		New-Item -Path $CopyTo  -ItemType Directory -Force | Out-Null 
		copy-item $CopyFrom\#ClientDLLs\CompetiotionOrdersLibrary.dll 							-destination $CopyTo 
		copy-item $CopyFrom\#ClientDLLs\ElectronicAuctionSABClientExtension.dll 				-destination $CopyTo 
		copy-item $CopyFrom\#ClientDLLs\Open2StageCompetitionSABClientExtension.dll 			-destination $CopyTo 
		copy-item $CopyFrom\#ClientDLLs\RequestProposalsSABClientExtension.dll 					-destination $CopyTo 
		copy-item $CopyFrom\#ClientDLLs\RequestQuotationsSABClientExtension.dll 				-destination $CopyTo 
		copy-item $CopyFrom\#ClientDLLs\OpenCompetitionSABClientExtension.dll 					-destination $CopyTo 
		copy-item $CopyFrom\#ClientDLLs\CompetitionLimitedParticipationSABClentExtension.dll 	-destination $CopyTo 

		## Копируем плагины сервера
		$CopyTo = "$CompileArtifacts\Plugins\server"    
		New-Item -Path $CopyTo  -ItemType Directory -Force | Out-Null
		copy-item $CopyFrom\#ServerDLLs\ElectronicAuctionSABServerExtension.dll 				-destination $CopyTo 
		copy-item $CopyFrom\#ServerDLLs\Open2StageCompetitionSABServerExtension.dll 			-destination $CopyTo 
		copy-item $CopyFrom\#ServerDLLs\RequestProposalsSABServerExtension.dll 				    -destination $CopyTo 
		copy-item $CopyFrom\#ServerDLLs\RequestQuotationsSABServerExtension.dll 				-destination $CopyTo 
		copy-item $CopyFrom\#ServerDLLs\OpenCompetitionSABServerExtension.dll 					-destination $CopyTo 
		copy-item $CopyFrom\#ServerDLLs\CompetitionLimitedParticipationSABServerExtension.dll 	-destination $CopyTo 
	}
	
    ## Копируем компоненты
	"`tCopy common"
    $CopyFrom = "$FromPath\Obj\Release"
    $CopyTo = $CompileArtifacts     

    $ArrayList = @()
    $ArrayList +=@("Arbiter")
    $ArrayList +=@("GeneralServer")
    $ArrayList +=@("TransportServer")
    $ArrayList +=@("CryptoProKeyManager")    
    $ArrayList +=@("RemoteControlAgent")
    $ArrayList +=@("ServerWatchDog")
    $ArrayList +=@("Starter")
    $ArrayList +=@("UpdateManager")

    $ArrayList  | foreach ($_) {          
        New-Item -Path $CopyTo\$_ -ItemType Directory -Force | Out-Null
        Get-ChildItem -Path $CopyFrom\$_ -Include *.exe,*.dll -Exclude  *resources.dll -Recurse | Copy-Item -Destination $CopyTo\$_  
        # файлик с версией сборки
		$ConfigJson.Version.ListNEW | Out-File $CopyTo\$_\Version.txt  
    }

    ## Копируем клиенты
    "`tCopy Client"
    $ArrayList = @() #список клиентов
	<# 1 #> if($ConfigExceptionsProject -eq "SAG") {$ArrayList +=@("ClientCandidate")}
	<# 2 #> if($ConfigExceptionsProject -eq "SAG") {$ArrayList +=@("ClientCustomer")}
	<# 3 #> if($SectionProject -eq "223") {$ArrayList +=@("ClientOperator223")} else {$ArrayList +=@("ClientOperator")}
    <# 4 #> $ArrayList +=@("ClientSecurityAdmin")

    $ArrayList  | foreach ($_) {           
        New-Item -Path $CopyTo\$_ -ItemType Directory -Force | Out-Null        
        #берем сборку целиком
        Get-ChildItem -Path $CopyFrom\$_    -Include *.exe,*.dll,*.config -Recurse | Copy-Item -Destination $CopyTo\$_      
        
		# добавляем локализацию библиотек
		if($ConfigExceptionsProject -ne "SAG") {
			Get-ChildItem -Path $CopyFrom\$_\ru -Include *.dll                -Recurse | Copy-Item -Destination $CopyTo\$_      
		}
    }
    Breaker
}


# Создаем клиенты и компоненты
Function CollectClient  {
	param (
        $CompileArtifacts,	
        $CollectClient,
        $Variables	
	)

    #------------- Собираем клиенты #-------------
    "`nPhase: Collect Compile Client: $ProjectType"

	if($SectionProject -eq "223") {
		## Превращаем дополнительно опаратора в заказчика
		"`tCreate ClientCustomer"    
		New-Item -Path $CompileArtifacts\ClientCustomer223 -ItemType Directory -Force | Out-Null 		
		copy-item $CompileArtifacts\ClientOperator223\*  -destination $CompileArtifacts\ClientCustomer223 -recurse  

		## Переименовываем ClientOperator.exe в ClientCustomer.exe   
		Remove-Item $CompileArtifacts\ClientCustomer223\ClientOperator.exe
		Remove-Item $CompileArtifacts\ClientCustomer223\ClientOperator.exe.config
		
		Remove-Item $CompileArtifacts\ClientOperator223\ClientOperator.exe
		Remove-Item $CompileArtifacts\ClientOperator223\ClientOperator.exe.config

		rename-item -path $CompileArtifacts\ClientCustomer223\ClientOperator223.exe        -newname ClientCustomer.exe -Force
		rename-item -path $CompileArtifacts\ClientCustomer223\ClientOperator223.exe.config -newname ClientCustomer.exe.config -Force

		rename-item -path $CompileArtifacts\ClientOperator223\ClientOperator223.exe        -newname ClientOperator.exe -Force
		rename-item -path $CompileArtifacts\ClientOperator223\ClientOperator223.exe.config -newname ClientOperator.exe.config -Force
		
	} elseif  ($ConfigExceptionsProject -ne "SAG") {
		## Превращаем дополнительно опаратора в заказчика
		"`tCreate ClientCustomer"    
		New-Item -Path $CompileArtifacts\ClientCustomer -ItemType Directory -Force | Out-Null 		
		copy-item $CompileArtifacts\ClientOperator\*  -destination $CompileArtifacts\ClientCustomer -recurse  

		## Переименовываем ClientOperator.exe в ClientCustomer.exe
		rename-item -path $CompileArtifacts\ClientCustomer\ClientOperator.exe        -newname ClientCustomer.exe
		rename-item -path $CompileArtifacts\ClientCustomer\ClientOperator.exe.config -newname ClientCustomer.exe.config
	}
	
	if($SectionProject -eq "223") {
		$ClientFolderOperator ="ClientOperator223"
		$ClientFolderCustomer ="ClientCustomer223"
	} else {
		$ClientFolderOperator ="ClientOperator"
		$ClientFolderCustomer ="ClientCustomer"
	}
			
    "`tAdd Starter"    
	if($ConfigExceptionsProject -eq "SAG") {
		copy-item  "$CompileArtifacts\Starter\*"  	      -destination "$CompileArtifacts\ClientCandidate"
	}
    copy-item  "$CompileArtifacts\Starter\*"  	          -destination "$CompileArtifacts\$ClientFolderCustomer"
    copy-item  "$CompileArtifacts\Starter\*"  	          -destination "$CompileArtifacts\$ClientFolderOperator"
    copy-item  "$CompileArtifacts\Starter\*"  	          -destination "$CompileArtifacts\ClientSecurityAdmin"	
    copy-item  "$CompileArtifacts\CryptoProKeyManager\*"  -destination "$CompileArtifacts\ClientSecurityAdmin"	

	# плагины
	if($ConfigExceptionsProject -ne "SAG") {
		## Кидаем плагины оператора в Client
		"`tAdd Plugins operator to Client"
		copy-item  "$CompileArtifacts\Plugins\operator\*"  	-destination "$CompileArtifacts\$ClientFolderCustomer"
		copy-item  "$CompileArtifacts\Plugins\operator\*"  	-destination "$CompileArtifacts\$ClientFolderOperator"
				
		## Кидаем плагины сервера в GeneralServer
		"`tAdd Plugins server to GS"
		copy-item  "$CompileArtifacts\Plugins\server\*"  	-destination "$CompileArtifacts\GeneralServer"
	}

	"`tCteate finish client"
    ## Компоненты для конкретного клиента
    $_Resource = "$PWDPoint\..\..\_Resource"
    $ArrayList = @()
	<# 1 #> if($ConfigExceptionsProject -eq "SAG") {$ArrayList +=@("ClientCandidate")}
    <# 2 #> $ArrayList +=@($ClientFolderCustomer)
    <# 3 #> $ArrayList +=@($ClientFolderOperator)
    <# 4 #> $ArrayList +=@("ClientSecurityAdmin")
		
    #$ArrayList  | foreach () {
	foreach ( $Client in $ArrayList )  {
        "`n`t`t$Client "	
        ## Кидаем доп компоненты
        "`t`t- Additional"		
		copy-item  "$_Resource\AdditionalsDLL\*"  		-destination "$CompileArtifacts\$Client" 
        copy-item  "$Variables\CertStore.sto"  	        -destination "$CompileArtifacts\$Client\CertStore.sto"
        copy-item  "$Variables\splash_$ProjectType.dat" -destination "$CompileArtifacts\$Client\splash.dat"
        $ConfigJson.Version.ListNEW | Out-File $CompileArtifacts\$Client\Version.txt 
		
		
		# берем $HostXML из конфигов (Config_*.ps1), для создания раздела клиента и его уникальный host.xml
		$HostXML | foreach ($_) {
			# создаем итоговый раздел клиента public/local/xor или чототамбудет внутри		
			if ($HostXML.count -eq 1) {
				$HostsGroupName = $_.HostsGroupName
				$HostsGroupCert = $_.HostsGroupCert
				$HostsGroupCert2012 = $_.HostsGroupCert2012
				$HostsAddress = $_.HostsAddress
				$HostsPort = $_.HostsPort
				$HostsURI = $_.HostsURI
				
				$HostsUpdateURL1 = $_.HostsUpdateURL1
				$HostsUpdateURL2 = $_.HostsUpdateURL2
				$HostsUpdateURL3 = $_.HostsUpdateURL3
			} else {	
				$i = $HostXML.IndexOF($_)                        
				$HostSection = $HostXML.HostSection[$i]
				
				$HostsGroupName = $HostXML.HostsGroupName[$i]
				$HostsGroupCert = $HostXML.HostsGroupCert[$i]
				$HostsGroupCert2012 = $HostXML.HostsGroupCert2012[$i]
				$HostsAddress = $HostXML.HostsAddress[$i]
				$HostsPort = $HostXML.HostsPort[$i]
				$HostsURI = $HostXML.HostsURI[$i]
				
				$HostsUpdateURL1 = $HostXML.HostsUpdateURL1[$i]
				$HostsUpdateURL2 = $HostXML.HostsUpdateURL2[$i]
				$HostsUpdateURL3 = $HostXML.HostsUpdateURL3[$i]
			}
			
			"`t`t- Created Section $HostSection"			
			$CopyFrom = "$CompileArtifacts\$Client"
			$CopyTo = "$ClientFolder\$HostSection\$Client"
			New-Item -Path $CopyTo -ItemType Directory -Force | Out-Null
			copy-item $CopyFrom\* -destination $CopyTo 
			
			## генерируем из шаблона host.xml 	
			"`t`t- host.xml" 
			# Делаем замену нужными параметрами из шаблона
			$hostPath = "$PathHostXMLFile\host_" + "$ProjectType" +"_"+ "$HostSection" + ".xml"			
			$HostTemplateInput = Get-Content $hostPath
			$HostTemplateOutput = "$ClientFolder\$HostSection\$Client\host.xml"					
			$HostTemplateInput = $HostTemplateInput `
						-replace '@HostsGroupName@',$HostsGroupName `
						-replace '@HostsGroupCert@',$HostsGroupCert `
						-replace '@HostsGroupCert2012@',$HostsGroupCert2012 `
						-replace '@HostsAddress@',$HostsAddress `
						-replace '@HostsPort@',$HostsPort `
						-replace '@HostsURI@',$HostsURI `
						-replace '@HostsUpdateURL1@', "$HostsUpdateURL1/$Client/update1.list" `
						-replace '@HostsUpdateURL2@', "$HostsUpdateURL2/$Client/update2.list" `
						-replace '@HostsUpdateURL3@', "$HostsUpdateURL3/$Client/update3.list" | Set-Content $HostTemplateOutput -Encoding UTF8
		
			## Создаем лист для обновления клиента
			"`t`t- Update file"
			& "$CompileArtifacts\UpdateManager\UpdateManager.exe" -i="$ClientFolder\$HostSection\$Client" -o="$ClientUpdate\$HostSection\$Client" -w="$HostsUpdateURL1/$Client"
			$ConfigJson.Version.ListNEW | Out-File $ClientUpdate\Version.txt 
			
			# При помощи некромании и отсутсвии здравого смысла, создаем уникальные апдейт листы
			$HostsUpdateURL = @()
			$HostsUpdateURL = @($HostsUpdateURL1, $HostsUpdateURL2, $HostsUpdateURL3)
			foreach ( $HostsUpdateURLPoint in $HostsUpdateURL )  {
				IF ($HostsUpdateURLPoint){				
					$i = $HostsUpdateURL.IndexOF($HostsUpdateURLPoint) 
					$i++

					copy-item $ClientUpdate\$HostSection\$Client\update.list -destination $ClientUpdate\$HostSection\$Client\update$i.list 
					
					$HostTemplateInput = Get-Content "$ClientUpdate\$HostSection\$Client\update$i.list"
					$HostTemplateOutput = "$ClientUpdate\$HostSection\$Client\update$i.list"							
					$HostTemplateInput = $HostTemplateInput -replace "$HostsUpdateURL1/$Client" ,"$HostsUpdateURLPoint/$Client" | Set-Content $HostTemplateOutput
				}
			}		
		}	
	}
	
    Breaker
} 


# останавливаем, копируем, запускаем компоненты развертки
Function CodeDelivery  {
	
	param (
        $Artifacts,	
        $ClientUpdate,
		$stage 
	)
	
	#Берем гибриды-списки из Config_Test.ps1	
	<#
	$GSPathList = @($PathGS)
	$TSPathList = @($PathTS)
	$WEBPathList = @($PathWEB)

	$GSServiseNameList = @($GSServiseName)
	$TSServiseNameList = @($TSServiseName)	

	#>
	
	# ========= 1
	# останавливаем службу GS/TS
	IF($stage -eq "1" -or $stage -eq "all") {
		"`nPhase: Code Delivery"

		"`tSTOP  GeneralServer:"
		$GSServiseNameList  | foreach ($_) { 
			UMServiseAction -ServisePath $ConfigJson.GS.IP -ServiseName $_ -ServiseStatus Stopped
		}
		
		"`tSTOP  TransportServer:"
		$TSServiseNameList  | foreach ($_) { 
			UMServiseAction -ServisePath $ConfigJson.TS.IP -ServiseName $_ -ServiseStatus Stopped
		}
			
		Breaker					
	
	# копируем GS/TS  WEB
		"`tCopy General/Transport Server" 	
		sleep 5 # ждем пока остановятся GS/TS	
		foreach ( $item in $GSPathList ) { 
			CopyTryHard -CopyFrom $Artifacts\GeneralServer 		-CopyTo $item
		}
			
		foreach ( $item in $TSPathList ) { 
			CopyTryHard -CopyFrom $Artifacts\TransportServer 	-CopyTo $item
		}
			
			
		"`tDelete WEB"  	
		foreach ( $item in $WEBPathList ) { 
			Get-ChildItem $item -recurse | foreach ($_) {
				Remove-Item $_.FullName -Force -Recurse       
			}	
		}
		
		"`tCopy WEB"  	
		foreach ( $item in $WEBPathList ) { 
			CopyTryHard -CopyFrom $ClientUpdate -CopyTo $item
		}			
	}
	
	# ========= 2  
	# накатываем скрипты
	IF($stage -eq "2" -or $stage -eq "all") {
		$folder = $ConfigJson.Version.ListNEW
		$PathListRUN = "$ScriptsList\$ProjectType\$folder\Scripts\2.ListRUN.txt"
		IF(Test-Path -Path $PathListRUN)  {
			"`tRun SQL"						
			ScriptsSQLRun -repository "$PathProjectSVN\SIMADATABASE" -ListRUNPath $PathListRUN	
		}
	}
	Breaker
	
	# ========= 3
	# запускаем службы GS/TS
	IF($stage -eq "3" -or $stage -eq "all") {		
		"`tSTART  GeneralServer:"
		$GSServiseNameList  | foreach ($_) { 
			UMServiseAction -ServisePath $ConfigJson.GS.IP -ServiseName $_ -ServiseStatus Running
		}
		
		"`tSTART  TransportServer:"
		$TSServiseNameList  | foreach ($_) { 
			UMServiseAction -ServisePath $ConfigJson.TS.IP -ServiseName $_ -ServiseStatus Running
		}

		Breaker
	}
}
 
# Сборка проекта в один архив для ПРОДА
Function CodeDeliveryProd {
    param ($Artifacts,
           $ClientUpdate,
           $ClientBuild,
		   $ListRUN )

	   
    
    "`nCollect Prod "
	
	"`tCreatedConfig"
	CreatedConfig -ClientBuild $Artifacts	
	
    $DateD = Get-Date -Format dd.MM.yyyy
	$DateT = Get-Date -Format HH-mm
    #$folder = $revision_SVN_ForDisplay # глобальная переменная 

    $ClientBuild = "$ClientBuild\Prod\"+ $ConfigJson.Version.ListNEW
	$ClientBuildFolder = $ClientBuild
    #if(Test-Path $ClientBuild )  {Remove-Item $ClientBuild -Force -Recurse  }
    New-Item -Path "$ClientBuild" -ItemType Directory -Force | Out-Null 
    
    "`tCollect Artifacts"
    move-item  "$Artifacts\Arbiter"         -destination "$ClientBuild\Arbiter"
    move-item  "$Artifacts\GeneralServer"   -destination "$ClientBuild\GeneralServer"
    move-item  "$Artifacts\TransportServer" -destination "$ClientBuild\TransportServer"
    move-item  $ClientUpdate -destination $ClientBuild

    "`tCollect Scripts"
    if ($SQLList.count -ne 0) {  
		#$folder = $revision_SVN_GMajor  +" ("+  $revision_from_Major +") (build " + $revision_from_Minor + "-" + $revision_to_Minor #+ ") " + $DateD  + " " + $DateT
        $folder = $ConfigJson.Version.ListNEW
		$ClientBuild = "$ClientBuild\Scripts"
        New-Item -Path $ClientBuild -ItemType Directory -Force | Out-Null 
        		
		
        
		
        $SQLListRUN | foreach {
            $Path = $_.Path
            $PathGroup = $_.PathGroup
            $Name = $_.Name      
            New-Item -Path $ClientBuild\$PathGroup -ItemType Directory -Force | Out-Null   
            copy-item  "$Path\$Name"  -destination $ClientBuild\$PathGroup
			
			#костыль копирование файлов "вбок"	часть1	
			# временная мера. копия скриптов в "отдельное место" для отдельного запуска
			$ShareScripts = "\\192.168.70.24\Releases\$SectionProject\$Project\$ProjectType\Scripts\$folder"
			New-Item -Path "$ShareScripts\$PathGroup" -ItemType Directory -Force | Out-Null  
			
			copy-item  "$Path\$Name"  -destination "$ShareScripts\$PathGroup" -recurse
        }
		#костыль копирование файлов "вбок"	часть2
		copy-item  "$ClientBuild\2.ListRUN.txt"  -destination "$ShareScripts" -recurse
		
	
    }  
	Breaker
	
    "`tArchive"
    $Path7z = "$env:ProgramFiles\7-Zip\7z.exe"    
	& $Path7z a -t7z -ssw -mx9 -sfx  -bb0 -sdel "$ClientBuildFolder.exe" "$ClientBuildFolder"

 }
 
 
  # запись результата в лог БД	
 Function WriteVersionDB {
    "`n--- Write version SQL Table INTO ProjectVersion"
	
    # Берем из Config_Common	
	<#	
	$SVN_GMajor 
	$SVN_Major  
	$SVN_Minor  
	
	$MainAccessURL 	 
	$MainAccessDB    
	$MainAccessLogin 
	$MainAccessPass	 
		
	$DBURL 	 
	$DBName  
	$DBLogin 
	$DBPass	 
	#>
	
	IF ($ProjectType -eq "Prod") {
	    # Запись версии в общий лог стенда для хранения, чтобы после произвести запись в Prod БД региона
		Invoke-Sqlcmd -Query "INSERT INTO ProjectVersion (SectionProject, ProjectType, Project, GMajor, Major, Minor, Date) 
							  VALUES ('$SectionProject','$ProjectType','$Project','$SVN_GMajor','$SVN_Major','$SVN_Minor','$DateForDB')" `
									-ServerInstance $MainAccessURL -Database $MainAccessDB -U $MainAccessLogin -P $MainAccessPass 
	} else {
		# Запись лога: БД - региона
		Invoke-Sqlcmd -Query "INSERT INTO ProjectVersion (SectionProject, ProjectType, Project, GMajor, Major, Minor, Date) 
							  VALUES ('$SectionProject','$ProjectType','$Project','$SVN_GMajor','$SVN_Major','$SVN_Minor','$DateForDB')" `
									-ServerInstance $DBURL -Database $DBName -U $DBlogin -P $DBpass 

		# Запись лога: БД - общий лог тестого стенд
		Invoke-Sqlcmd -Query "INSERT INTO ProjectVersion (SectionProject, ProjectType, Project, GMajor, Major, Minor, Date) 
							  VALUES ('$SectionProject','$ProjectType','$Project','$SVN_GMajor','$SVN_Major','$SVN_Minor','$DateForDB')" `
									-ServerInstance $MainAccessURL -Database $MainAccessDB -U $MainAccessLogin -P $MainAccessPass 
					
		# запись лога: в файл	
		$ConfigJson.Version.ListNEW | Out-File $PWDPoint\VersionBuild_$ProjectType.txt  -Append
	}
	
    Breaker
}

 # запись результата в лог БД	
 Function WriteVersionDBProd {

	
    # Берем из Config_Common	
	<#	
	$SVN_GMajor 
	$SVN_Major  
	$SVN_Minor  
	
	$MainAccessURL 	 
	$MainAccessDB    
	$MainAccessLogin 
	$MainAccessPass	 
		
	$DBURL 	 
	$DBName  
	$DBLogin 
	$DBPass	 
	#>
	"====================== UpdateMachine--Start update AIS ================" 
	"Project: $SectionProject, $Project, $ProjectType"
	
	"`n--- Write version to SQL ProjectVersion"

	$CorVersion = Invoke-Sqlcmd -Query "SELECT TOP 1 * 
											,CONVERT(nvarchar(30), Date, 104) Datelist 
											,CONVERT(nvarchar(30), Date, 108) DatelistTime   
									    FROM [ProjectVersion]
									    ORDER BY [Date] desc " -ServerInstance $DBURL -Database $DBName -U $DBlogin -P $DBpass #-ErrorAction Stop
									  
	$NewVersion = Invoke-Sqlcmd -Query "SELECT TOP 1 *   
											,CONVERT(nvarchar(30), Date, 104) Datelist 
											,CONVERT(nvarchar(30), Date, 108) DatelistTime 
											,Date as DateDB											
									    FROM [ProjectVersion]
									    WHERE [SectionProject] = '$SectionProject'
											AND [ProjectType] = '$ProjectType '
											AND [Project] = '$Project'
									    ORDER BY [Date] desc " -ServerInstance $MainAccessURL -Database $MainAccessDB -U $MainAccessLogin -P $MainAccessPass 									  

		

	"`ncor Version: " + $CorVersion.GMajor + " (build " + $CorVersion.Minor + ") " + $CorVersion.Datelist  +" "+ $CorVersion.DatelistTime
	$VersionBuild = $NewVersion.GMajor + " (build " + $NewVersion.Minor + ") " + $NewVersion.Datelist  +" "+$NewVersion.DatelistTime
	"New Version: " + $VersionBuild
	
	[string]$GMajor = $NewVersion.GMajor
	[string]$Major  = $NewVersion.Major
	[string]$Minor  = $NewVersion.Minor	
	[string]$DateDB  = $NewVersion.Datelist  +" "+$NewVersion.DatelistTime
	#[string]$DateDB  = $NewVersion.DateDB  
$DateDB 
    Breaker
    IF (!($CI -eq "CI")) { PauseKey}	
	  
	  
    # Запись лога: БД - региона
    Invoke-Sqlcmd -Query "INSERT INTO ProjectVersion (SectionProject, ProjectType, Project, GMajor, Major, Minor, Date) 
                          VALUES ('$SectionProject','$ProjectType','$Project','$GMajor','$Major','$Minor','$DateDB')" `
                                -ServerInstance $DBURL -Database $DBName -U $DBlogin -P $DBpass #-ErrorAction Stop
							
                        
    # запись лога: в файл	
    $VersionBuild | Out-File .\VersionBuild_$ProjectType.txt  -Append

    Breaker
}



  # запись результата в лог БД	
 Function WriteVersionXML {

	# пишем результат обновы в XML
	VersionXMLRewrite -ServerVersion $ServerVersion `
					  -SectionProject $SectionProject `
					  -Project $Project `
					  -ProjectType $ProjectType	`
					  -revision_to_Major $revision_to_Major  `
					  -revision_to_Minor $revision_to_Minor `
					  -revision_SVN_GMajor $revision_SVN_GMajor
	Breaker
}


# Поддерживаем кол-во файлов/папаок в числе последних 5 
Function RemoveDescending {
	param (
		$path
	)


	IF(Test-Path -Path $path) {
		$n = 5
		$items = Get-ChildItem "$path"
		echo "`n"
		if ($items.count -gt $n ) {
			"--- Dell $item "
			cd "$path"
			$items | 
			Sort-Object Name -Descending | 
			Select-Object -Last ($items.count - $n) | 
			Foreach-Object { 
				echo "$_"
				Remove-Item $_  -recurse
			}            
		}	
	}
}

# Копируем клиент на шару
 function CopyShareClient {
    param ($PathShareClient,
           $Artifacts
   )
	 
	$PathShareClient = "$PathShareClient\$SectionProject\$Project\$ProjectType"
    "`n--- Copy ShareClient: $PathShareClient"

    if(Test-Path $PathShareClient ) {
	    "Client accece"
    } else {      
       #CopyLite -CopyFrom $Point\$Artifacts -CopyTo $PathShareClient -Name ShareClient	
	   
		New-Item -Path $PathShareClient -ItemType Directory -Force | Out-Null   
		copy-item  $Artifacts\*  -destination $PathShareClient	 -recurse   
    }
}



Function DeployApp {
	param($disk,
		  $PathArchiv
	)
	
<# 	## Config_Common.ps1
	$APPLogin
	$APPPass
	$APPPath #>
	
	"`n`t--- Copy Binary APP"
    "PathAPP:  " + $APPPath
    "Net disk: " + $disk	
		
	# если есть сетевой диск с буквой $disk, отключаем его
	$disk = $disk+":"
    if(Test-Path $disk) {net use  $disk  /delete /y  | Out-Null }
	   
	#подключаем диск до АПП региона
	$net = New-Object -ComObject WScript.Network 
	$net.MapNetworkDrive( $disk, $APPPath, $false, $APPLogin, $APPPass ) | Out-Null
	#net use $disk  $APPPath /user:$APPLogin $APPPass | Out-Null 
	
	# Проверка конекта до АПП
    IF(Test-Path $APPPath ) {
        $StatusAPP = "Connected" 
    } else  {
        $StatusAPP = "Not Connected"                         
    }




    $file = Get-ChildItem $PathArchiv -Filter *.exe  | Sort-Object LastWriteTime | Select-Object -Last 1
    "`n-- App: " + $StatusAPP
    "-- Bin: " + $file.name

    #Проверяем готовность
    Breaker 
	
	# Копируем на сервак компоненты обновления
    robocopy $PathArchiv 						$APPPath\Prod 		$file.name 						/W:10 /Z  /NJS
    robocopy "$PWDPoint\..\..\_Resource\" 		$APPPath\_modules 	Prod_ModuleFunction.ps1 		/W:10 /Z  /NJS
    robocopy "$PWDPoint\..\..\_Resource\" 		$APPPath\_modules 	Prod_ModuleServerAssembly.ps1 	/W:10 /Z  /NJS
	robocopy "$PWDPoint\..\..\_Resource\" 		$APPPath\ 			Prod_Start.ps1 					/W:10 /Z  /NJS
    robocopy "$PWDPoint\ClientBuild\Artifacts\" $APPPath\_modules 	Config.ps1  					/W:10 /Z  /NJS


    # отключаем сетевой диск
    if(Test-Path $disk) {net use  $disk  /delete /y  | Out-Null }

}
