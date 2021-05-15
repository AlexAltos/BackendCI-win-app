## Build__Prod.ps1

Clear-Host
$CI = $args[0]
$error.clear()
$PWDPoint = $PWD
$watch = [System.Diagnostics.Stopwatch]::New() 
$watch.Start()

"Wait, just wait..."

## Входные параметры  
$ProjectType = "Prod"	                        # указываем тип  Test/PreProd/Prod
$SectionProject = (Get-Item $PWDPoint\..\).Name # используем физическое название верхнего каталога для запуска конфигов
$Project = (Get-Item $PWDpoint).Name            # используем физическое название каталога для запуска конфигов
$PathProjectSVN = & "$PWDPoint\..\..\_Resource\Switch_PathProjectSVN.ps1" $SectionProject $Project $ProjectType # берем путь проекта, из общего шаблона переключателя
$PathConfigFile   = "$PWDPoint\_Variables\Config_Prod.ps1"
$PathHostXMLFile  = "$PWDPoint\..\..\_Resource"

## ===> Раскрыть комит в обход общего конфига, если надо другой путь до репозитория
#$PathProjectSVN = "D:\Projects\4Publication\44ReleaseBranches\3.7.1"

## ===> Раскрыть комит в обход общего конфига, если надо другой путь до ключевых переменных 
#$PathConfigFile  = "$PWDPoint\_Variables\Config_Test.ps1"
#$PathHostXMLFile = "$PWDPoint\_Variables"     #Host.XML


# Подключение ядра процесса
<# step 1 #> . "$PWDPoint\..\..\_Resource\Module_Function.ps1"
<# step 2 #> . "$PathConfigFile" $SectionProject $Project $ProjectType $PathProjectSVN 
<# step 3 #> . "$PWDPoint\..\..\_Resource\Config_CommonExceptions.ps1"
<# step 4 #> . "$PWDPoint\..\..\_Resource\Config_Common.ps1"
<# step 5 #> . "$PWDPoint\..\..\_Resource\Module_ServerAssembly.ps1"


# Процесс сборки, все стадии берем из Module_ServerAssembly	
<# Phase 1 #> LoadPreparation
<# Phase 2 #> CollectArtifacts -FromPath $PathProjectSVN -CompileArtifacts $Artifacts -ClearBinaries $ClientBuild
<# Phase 3 #> CollectClient    -Variables $Variables     -CompileArtifacts $Artifacts -CollectClient $ClientBuild	
<# Phase 4 #> CodeDeliveryProd -Artifacts $Artifacts -ClientUpdate $ClientUpdate -ClientBuild $ScriptsList -ListRUN $SQLListRUN
<# Phase 5 #> WriteVersionDB
<# Phase 6 #> DeployApp -disk "Y"  -PathArchiv "$PWDPoint\_ScriptsList\Prod"
<# Phase 7 #> RemoveDescending -path "$ScriptsList\$ProjectType" # удаляем списки скриптов
	
CopyShareClient -PathShareClient $PathShareClient -Artifacts $ClientFolder #копируем на шару клиенты

$watch.Stop()
Write-Host "`nElapsed time: " $watch.Elapsed #Время выполнения


IF (!($CI -eq "CI")) { pause}

