
$SectionProject = $args[0]
$Project 		= $args[1]
$ProjectType    = $args[2]
	

if ($SectionProject -eq "44") {
	Switch ($ProjectType)  {
		'test' 		{ $PathProjectSVN = "D:\Projects\test.v3" }	
		'PreProd' 	{ $PathProjectSVN = "d:\Projects\4Publication\44ReleaseBranches\3.7.2\" }		
		'Prod'  	{ $PathProjectSVN = "d:\Projects\4Publication\44ReleaseBranches\3.7.2\" }		
	}
} elseif ($SectionProject -eq "223") {
	Switch ($ProjectType)  {
		'test' 		{ $PathProjectSVN = "d:\Projects\test.v3\" }	
		'PreProd' 	{ $PathProjectSVN = "d:\Projects\4Publication\223ReleaseBranches\2.15\" }		
		'Prod'  	{ $PathProjectSVN = "d:\Projects\4Publication\223ReleaseBranches\2.15\" }			
	}
} elseif ($SectionProject -eq "Other") {
	if($Project -eq "SAG") {
		Switch ($ProjectType)  {
		'test' 		{ $PathProjectSVN = "d:\Projects\Agro.v2\" }	
		'PreProd' 	{ $PathProjectSVN = "d:\Projects\Agro.v2\" }		
		'Prod'  	{ $PathProjectSVN = "D:\Projects\Agro.v2\" }		
		}
	} elseif($Project -eq "BurTenderPublic") {
		Switch ($ProjectType)  {
		'test' 		{ $PathProjectSVN = "d:\Projects\BurTenderPublic\" }	
		'PreProd' 	{ $PathProjectSVN = "d:\Projects\BurTenderPublic\" }		
		'Prod'  	{ $PathProjectSVN = "d:\Projects\BurTenderPublic\" }		
		}
	}
	
}

$PathProjectSVN