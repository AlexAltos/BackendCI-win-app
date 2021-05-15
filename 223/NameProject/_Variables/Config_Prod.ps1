
#==== Аргументы на вход
$SectionProject = $args[0] # 44 223 Other
$Project =        $args[1] # Chita
$ProjectType =    $args[2] # Test PreProd Prod

if ($args[3]) {
	$PathProjectSVN = $args[3] # "D:\projects\test.v3"
	$PathProjectSVN = (Get-Culture).TextInfo.ToTitleCase($PathProjectSVN.ToLower()) #Вписать символ диска всегда в ВЕРХНЕМ регитре
	IF( $PathProjectSVN.Substring($PathProjectSVN.Length - 1) -eq "\" ) {# проверяем последний символ в строке, если он \ то удаляем
		$PathProjectSVN = $PathProjectSVN.Substring(0 , $PathProjectSVN.length - 1)
	}
	$GMajor = (Get-Item $PathProjectSVN).Name
}

#===== основные настройки проекта      
$GS  = "192.168.205.35"
$TS  = "192.168.205.32"
$Web = "192.168.205.33"

# Путь до сервера и WEB
$PathGS  = "\\$GS\servers\GeneralServer_Krai223"
$PathTS  = "\\$TS\servers\TransportServer_Krai223" 
$PathWEB = "\\$Web\Inetpub\wwwroot\Krai223\Programm\Updates.v3"

# Название служб серверов
$GSServiseName = "GS_223_Krai"
$TSServiseName = "TS_223_Krai"

# Гибриды-списки переменных для использования
$PathList = @($PathGS, $PathTS, $PathWEB )
$GSPathList = @($PathGS)
$TSPathList = @($PathTS)
$WEBPathList = @($PathWEB)

$GSServiseNameList = @($GSServiseName)
$TSServiseNameList = @($TSServiseName)

#===== Hosts.xml
$HostXML = @()
$HostSection = "Public"
$HostsGroupName = "Край 223-ФЗ"
$HostsGroupCert = "79F3CED22DC0F00C3730392C4BDB74DD7D8BA7D8"
$HostsGroupCert2012 = "0283C38800DBAB41BC4C51949A8DEFE101"
$HostsAddress = "5.5.5.5"
$HostsPort = "80"
$HostsURI = "Krai223"
$HostsUpdateURL1 = "http://6.6.6.6/Programm/updates.v3/public"
#$HostsUpdateURL2 = ""
#$HostsUpdateURL3 = ""
$HostXML += [PSCustomObject]@{HostSection=$HostSection; 
						   HostsGroupName=$HostsGroupName; 
						   HostsGroupCert=$HostsGroupCert;
						   HostsGroupCert2012 =$HostsGroupCert2012; 
						   HostsAddress =$HostsAddress;
						   HostsPort =$HostsPort;
						   HostsURI =$HostsURI;
						   HostsUpdateURL1 =$HostsUpdateURL1;
						   HostsUpdateURL2 =$HostsUpdateURL2;
						   HostsUpdateURL3 =$HostsUpdateURL3;} 
						   			   
						  		   