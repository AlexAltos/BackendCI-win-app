## Config_TemplateTestPreProd.ps1
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

# Основные адреса      
$GS  = "192.168.70.28"
$TS  = "192.168.70.29"
$Web = "192.168.70.30"

# Название служб серверов
$GSServiseName = "GS_$ProjectType$SectionProject" +"_"+ "$Project"
$TSServiseName = "TS_$ProjectType$SectionProject" +"_"+ "$Project"

$PathGS  = "\\$GS\Server\GeneralServer_$ProjectType$SectionProject" +"_"+ "$Project"
$PathTS  = "\\$TS\Server\TransportServer_$ProjectType$SectionProject" +"_"+ "$Project"
$PathWEB = "\\$Web\wwwroot\SAB\updates\$SectionProject\$Project\$ProjectType"

# Гибриды-списки переменных для использования
$PathList = @($PathGS, $PathTS, $PathWEB)
$GSPathList = @($PathGS)
$TSPathList = @($PathTS)
$WEBPathList = @($PathWEB)

$GSServiseNameList = @($GSServiseName)
$TSServiseNameList = @($TSServiseName)
	


#===== Hosts.xml
$HostXML = @()					   
$HostSection = "Public"
$HostsGroupName = $SectionProject + " - " + $Project + " - " + $ProjectType
$HostsGroupCert = "Cert-000"
$HostsGroupCert2012 = "Cert2012-000"
$HostsAddress = "7.7.7.7"
$HostsPort = "80"
$HostsURI = "$SectionProject$Project$ProjectType"
$HostsUpdateURL1 = "http://9.9.9.161/updates/$SectionProject/$Project/$ProjectType/$HostSection"
$HostsUpdateURL2 = "http://9.9.9.200/updates/$SectionProject/$Project/$ProjectType/$HostSection"
$HostsUpdateURL3 = ""
$HostXML += [PSCustomObject]@{HostSection=$HostSection; 
						   HostsGroupName=$HostsGroupName; 
						   HostsGroupCert=$HostsGroupCert;
						   HostsGroupCert2012 =$HostsGroupCert2012; 
						   HostsAddress =$HostsAddress;
						   HostsPort =$HostsPort;
						   HostsURI =$HostsURI;
						   HostsUpdateURL1 =$HostsUpdateURL1;
						   HostsUpdateURL2 =$HostsUpdateURL2;
						   HostsUpdateURL3 =$HostsUpdateURL3} 
		
		
