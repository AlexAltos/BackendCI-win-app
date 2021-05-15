Function LeadPreparation  {

	$Point = $PWD 
	$error.Clear()

	"====================== UpdateMachine--Start update AIS ================" 
	"Project: $SectionProject, $Project, $ProjectType"

	#Берем гибриды-списки переменные из Config.ps1	

	$echoerrorr=0
	# Проверка на присутсвие			
	$PathList  | foreach ($_) { 
		$echo = ""
		$CheckerPathECHO = UMChecker -TestPath $_	
		$echo = "Path " + $CheckerPathECHO[0] +"  - "+ $CheckerPathECHO[1]
		IF ($CheckerPathECHO[2] -gt 0) {
			Write-host $echo -ForegroundColor red -BackgroundColor black
			$echoerrorr++
		} else {
			$echo
		}
		
	}	
		
	# GeneralServer"	
	$GSServiseNameList  | foreach ($_) { 
		$echo = ""
		$CheckerPathECHO = UMChecker -ServisePath $GS -ServiseName $_ 	
		$echo = "GS " + $CheckerPathECHO[0] +"  - "+ $CheckerPathECHO[1] 
		IF ($CheckerPathECHO[2] -gt 0) {
			Write-host $echo -ForegroundColor red -BackgroundColor black
			$echoerrorr++
		} else {
			$echo
		}		
	}
	
	# TransportServer"
	$TSServiseNameList  | foreach ($_) { 
		$echo = ""
		$CheckerPathECHO = UMChecker -ServisePath $TS -ServiseName $_ 	
		$echo = "TS " + $CheckerPathECHO[0] +"  - "+ $CheckerPathECHO[1] 
		IF ($CheckerPathECHO[2] -gt 0) {
			Write-host $echo -ForegroundColor red -BackgroundColor black
			$echoerrorr++
		} else {
			$echo
		}		
	}
	
	
	# SQL DataBase"	
	IF ($Project -eq 'AltaiRepublic' -or $SectionProject -eq "223") {
		"SKIP SQL test"
	} else {
		echo = ""	
		$CheckerPathECHO = Test-SQLDatabase -Server $DBURL -Database $DBName -Username $DBLogin -Password $DBPass
		$echo = "DataBase " + $CheckerPathECHO[0] +"  - "+ $CheckerPathECHO[1] 
		IF ($CheckerPathECHO[2] -gt 0) {
			Write-host $echo -ForegroundColor red -BackgroundColor black
			$echoerrorr++
		} else {
			$echo
		}
	}
		
	
	Breaker
		
	if ($echoerrorr -gt 0) {
		Write-host "`n----------- Not all steps ready"  -ForegroundColor red -BackgroundColor black   
		pause	"press button..."
		exit
	}

	
	
	"`n-- BinaryFile"		
	$BinaryFile = "$Point\Prod"
	$file = Get-ChildItem $BinaryFile -Filter *.exe  | Sort-Object LastWriteTime | Select-Object -Last 1
	$file.name
	
	$APPFolder = Get-ChildItem $BinaryFile | Where-Object {$_.mode -match "d"}  | Sort-Object LastWriteTime | Select-Object -Last 1
	$APPexe =  Get-ChildItem $BinaryFile | Sort-Object LastWriteTime | Select-Object -Last 1 
	
	if( !($APPFolder.name -eq ($APPexe).BaseName)) {		 	
	} else {"-- File exist"} 
	
	Breaker
	PauseKey


	# ========= 2
	
	if( !($APPFolder.name -eq ($APPexe).BaseName)) {	
		Set-Location $BinaryFile
		& .\$file	 	
	}
	
	# останавливаем службу GeneralServer/TransportServer
	"`tSTOP  GeneralServer:"
	$GSServiseNameList  | foreach ($_) { 		
		UMServiseAction -ServisePath $GS -ServiseName $_ -ServiseStatus Stopped
	}
	
	"`tSTOP  TransportServer:"
	$TSServiseNameList  | foreach ($_) {
		UMServiseAction -ServisePath $TS -ServiseName $_ -ServiseStatus Stopped
	}
	
	Breaker
	
	
	# ========= 3
	# копируем GS/TS  WEB
	echo "`n-- Copy General/Transport Server" 
	$APPFolder = Get-ChildItem $BinaryFile | Where-Object {$_.mode -match "d"}  | Sort-Object LastWriteTime | Select-Object -Last 1
	
	Set-Location $BinaryFile\$APPFolder
	sleep 5 # ждем пока остановятся GS/TS	
	foreach ( $item in $GSPathList ) { 
		"`n$item"
		CopyTryHard -CopyFrom .\GeneralServer 		-CopyTo $item
	}
		
	foreach ( $item in $TSPathList ) { 
		"`n$item"
		CopyTryHard -CopyFrom .\TransportServer 	-CopyTo $item
	}
		
		
	foreach ( $item in $WEBPathList ) { 
		if( $item ) {
			"From: $item"
			Get-ChildItem $item -recurse | foreach ($_) {
				"CLEANING: " + $_.Name
				Remove-Item $_.FullName -Force -Recurse       
			}	
		}
	}
	
	
	"`tCopy WEB"  	
	foreach ( $item in $WEBPathList ) { 
		CopyTryHard -CopyFrom .\Update -CopyTo $item
	}
	
	# ========= 4  
	# накатываем скрипты
	if(Test-Path "$BinaryFile\$APPFolder\Scripts" )  {
		 "`n-- Run SQL:"	
		IF ($Project -eq 'AltaiRepublic' -or `
			$Project -eq 'Chita' -or `
			$Project -eq 'Kemerovo' -or `
			$Project -eq 'Khakasia' -or `
			$SectionProject -eq "223" -or `
			$Project -eq 'SAG' ) {
			" Invoke-Sqlcmd - not found"
			PauseKey
		} else {
			SQLRun -repository "$BinaryFile\$APPFolder\Scripts" 
		}		
	} 
	#Breaker
	
	# ========= 5
	# запускаем службу GeneralServer/TransportServer
	"`tSTART  GeneralServer:"
	$GSServiseNameList  | foreach ($_) { 
		UMServiseAction -ServisePath $GS -ServiseName $_ -ServiseStatus Running
	}
	
	"`tSTART  TransportServer:"
	$TSServiseNameList  | foreach ($_) { 
		UMServiseAction -ServisePath $TS -ServiseName $_ -ServiseStatus Running
	}
	
	# ========= 6
	# Убираем использованный бинарник
	"`n-- Delete old BinaryFile "  
	Set-Location $BinaryFile
	if(Test-Path $BinaryFile\$APPFolder )  {
		Remove-Item $BinaryFile\$APPFolder -Force -Recurse   
	}
	
	# оставляем актуальные 5 версий
	$folders = Get-ChildItem $BinaryFile -Include *.exe -Recurse
	$i = 0
	While ($i -lt $folders.count-5) {
	   Remove-Item $folders[$i] -force -recurse
	   #"`n $folders[$i]"
	   $i++
	}

	
	# запись результата в лог БД	
    "`n--- Write version to SQL ProjectVersion"
    $APPFolder.Name | Out-File $Point\VersionBuild_$ProjectType.txt  -Append

}
