##Config_CommonExceptions.ps1
#####################################################
## Проверка на принадлежность к разделу проекта
$ConfigExceptionsProject=""
IF ($Project -eq "AG")          { $ConfigExceptionsProject = "SAG"} 
IF ($Project -eq "AgroGroup") { $ConfigExceptionsProject = "SAG"} 



