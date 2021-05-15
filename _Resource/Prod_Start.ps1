# --------------
. .\_modules\Config.ps1
. .\_modules\Prod_ModuleFunction.ps1
. .\_modules\Prod_ModuleServerAssembly.ps1

$host.ui.RawUI.WindowTitle = "UpdateMachine--Start update AIS -- $SectionProject --  $Project -- $ProjectType -- "

LeadPreparation

pause "press button..."