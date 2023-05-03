#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} OM200FIM
//TODO Grava no painel os campos referente a carga. GAP 078
@author Gerson Luz
@since 16/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
user function OM200FIM()

Local lRet := .t.
	//if findfunction("u_G0507809")
	//	lRet := u_G0507809()
	//endif

	if findfunction("u_GTOMS007")
		lRet := u_GTOMS007()
	endif
	
return lRet
