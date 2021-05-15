## Build__Prod_WriteVersion.ps1

Clear-Host
$CI = $args[0]
$error.clear()
$PWDPoint = $PWD

"Wait, just wait..."

## Входные параметры  
$ProjectType = "Prod"	                        # указываем тип  Test/PreProd/Prod
$SectionProject = (Get-Item $PWDPoint\..\).Name # используем физическое название верхнего каталога для запуска конфигов
$Project = (Get-Item $PWDpoint).Name            # используем физическое название каталога для запуска конфигов
$PathProjectSVN = & "$PWDPoint\..\..\_Resource\Switch_PathProjectSVN.ps1" $SectionProject $Project $ProjectType # берем путь проекта, из общего шаблона переключателя
$PathConfigFile   = "$PWDPoint\..\..\_Resource\Config_TemplateTestPreProd.ps1"
$PathHostXMLFile  = "$PWDPoint\..\..\_Resource"

# Подключение ядра процесса
<# step 1 #> . "$PWDPoint\..\..\_Resource\Module_Function.ps1"
<# step 2 #> . "$PathConfigFile" $SectionProject $Project $ProjectType $PathProjectSVN 
<# step 3 #> . "$PWDPoint\..\..\_Resource\Config_CommonExceptions.ps1"
<# step 4 #> . "$PWDPoint\..\..\_Resource\Config_Common.ps1"
<# step 5 #> . "$PWDPoint\..\..\_Resource\Module_ServerAssembly.ps1"


WriteVersionDBProd
	
	
IF (!($CI -eq "CI")) { pause}