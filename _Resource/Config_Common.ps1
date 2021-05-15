## Config_Common.ps1

#######################################
## Собираем системные переменные
# Константы
$Variables =    "$PWDPoint\_Variables" # место хранения особенности региона
$ScriptsList =  "$PWDPoint\_ScriptsList"   
$ClientBuild =  "$PWDPoint\ClientBuild"
$Artifacts =    "$PWDPoint\ClientBuild\Artifacts" # место хранения собранных артефактов
$ClientFolder = "$PWDPoint\ClientBuild\Clients"   # готовые клиенты
$ClientUpdate = "$PWDPoint\ClientBuild\Update"    # апдейты клиента для веба

# Могут меняться
$PathShareClient =    "\\192.168.70.250\share\clients"                             # путь куда копировать собранные клиенты для расшаривания
$PathKeePassFound =   "C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe" # Прога для открытия контейнера паролей			
$PathKeePassDatabase ="$PWDPoint\..\..\_Resource\Database.v5.kdbx"                 # контейнер паролей
$ServerVersion =      "$PWDPoint\..\..\_Resource\ServerVersion.xml"	               # Список установленных версий	
#######################################

## Получаем параметры на вход стенда БД
$KeePassObject = Get-PasswordFromKeePass  -PathKeePass $PathKeePassFound -PathKeePassDatabase $PathKeePassDatabase -ParentGroupName "SQLTest" -Title "MainAccess"   #-ErrorAction SilentlyContinue
$MainAccessURL 	 = $KeePassObject.URL
$MainAccessDB    = $KeePassObject.Notes
$MainAccessLogin = $KeePassObject.UserName
$MainAccessPass	 = $KeePassObject.Password


# берем лог пасс SQL конкретного проекта из KeePassDatabase
IF (!$Title){ # проверка на присутсвие переменной созданной в исключении из Config_CommonExceptions.ps1 
	$Title="$SectionProject"+"_"+"$Project"
}

IF($ProjectType -eq "Prod") {
	$ParentGroupName = "SQL"
} else {
	$ParentGroupName = "SQLTest"
}
$KeePassObject = Get-PasswordFromKeePass  -PathKeePass $PathKeePassFound -PathKeePassDatabase $PathKeePassDatabase -ParentGroupName $ParentGroupName -Title $Title  #-ErrorAction SilentlyContinue
$DBURL 	 = $KeePassObject.URL
$DBLogin = $KeePassObject.UserName
$DBPass	 = $KeePassObject.Password
IF($ProjectType -eq "Prod") {
	$DBName = $KeePassObject.Notes 
} else {
	$DBName  = "$ProjectType$SectionProject" +"_"+ "$Project"
}

# берем лог пасс APP конкретного проекта из KeePassDatabase
IF($ProjectType -eq "Prod") {
	$ParentGroupName = "APP"
	$KeePassObject = Get-PasswordFromKeePass  -PathKeePass $PathKeePassFound -PathKeePassDatabase $PathKeePassDatabase -ParentGroupName $ParentGroupName -Title $Title  #-ErrorAction SilentlyContinue
	$APPPath  = $KeePassObject.URL
	$APPLogin = $KeePassObject.UserName
	$APPPass  = $KeePassObject.Password
}



# Считываем репозиторий, чтобы узнать новую версию
$VersionSVN = VersionSVN -PathProjectSVN $PathProjectSVN -SectionProject $SectionProject -ProjectType $ProjectType -Project $Project
$SVN_GMajor = $GMajor 
$SVN_Major  = $VersionSVN[0]
$SVN_Minor  = $VersionSVN[1]
$SVN_MinorBranch = $VersionSVN[2] 



# Считываем DataBase и получаем текущую версию FROM [ProjectVersion]
$DataBase = Invoke-Sqlcmd -Query "SELECT TOP 1 
									GMajor
									,Major
									,Minor
									,CONVERT(nvarchar(30), Date, 104) Datelist 
									,CONVERT(nvarchar(30), Date, 108) DatelistTime 
								FROM [ProjectVersion] 
								ORDER BY [Date] desc" -ServerInstance $DBURL -Database $DBName -U $DBlogin -Password $DBpass   #-ErrorAction SilentlyContinue -ErrorVariable Failed                 
$DB_GMajor   = $DataBase.GMajor 
$DB_Major    = $DataBase.Major
$DB_Minor    = $DataBase.Minor 
$DB_Date     = $DataBase.Datelist 
$DB_DateTime = $DataBase.DatelistTime


# Листы для отображения
$DateY = Get-Date -Format yyyy
$DateD = Get-Date -Format dd.MM.yyyy
$DateT = Get-Date -Format HH-mm
# Кусок даты для записи в БД
$DateForDB1 = Get-Date -Format dd-MM-yyyy 
$DateForDB2 = Get-Date -Format HH:mm
$DateForDB = "$DateForDB1 $DateForDB2"

$VersionCurrent = $DB_GMajor  + " (" + $DB_Major  + ") (build " + $DB_Minor  + ") " + $SectionProject + $Project +" "+ $DB_Date +" "+ $DB_DateTime
$VersionNEW     = $SVN_GMajor + " (" + $SVN_Major + ") (build " + $SVN_Minor + ") " + $SectionProject + $Project +" "+ $DateD +" "+ $DateT
$ForWEB         = "(build " + $SVN_Minor + ") "+ $DateD +" "+ $DateT



	
	
####################################
## Структуирование и запись переменных в Json
$json = @"
{
	"firstName": "Иван",
	"lastName": "Иванов",
	"GS" : {
		"IP"   : "$GS",
		"Name" : "$GSServise"
	},
	
	"TS" : {
		"IP"   : "$TS",
		"Name" : "$TSServise"
	},
	"WEB" : {
		"IP"   : "$Web"
	},
	

	"Version": [
		{ 
		  "Current" : [	
			{
			  "GMajor" : "$DB_GMajor",	
			  "Major"  : "$DB_Major ",
			  "Minor"  : "$DB_Minor ",
			  "Date"   : "$DB_Date"
			}
		   ]
		},
		{ 		
		  "New" : [	
			{
			  "GMajor" : "$SVN_GMajor",	
			  "Major"  : "$SVN_Major",
			  "Minor"  : "$SVN_Minor",
			  "CMinor" : "$SVN_СMinor",
			  "MinorBranch" : "$SVN_MinorBranch"
			}
		   ]
		},
		{ "ListCurrent" : "$VersionCurrent" },
		{ "ListNEW"     : "$VersionNEW" }
	]
}	

"@

$ConfigJson = ConvertFrom-Json -InputObject $json
