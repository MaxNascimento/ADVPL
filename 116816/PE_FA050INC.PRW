
#Include "Protheus.CH"
/*/{Protheus.doc} FA050INC
//TODO PONTO DE ENTRADA ANTES DA INCLUSAO DO TITULO A PAGAR
@author alex.bender
@since 12/06/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function FA050INC()
	Local lRet := .T.

	If IsInCallStack("U_F0600105")
		Return lRet
	Endif

	If lRet
		If IsBlind() .And. ISINCALLSTACK("WFHTTPRET") //tratamento para chamada via Workflow.   
			cModulo := "SIGAAGR"//modulo Agro
		EndIf
		lRet := U_G0501601(M->E2_VENCTO, M->E2_TIPO,cModulo,M->E2_PREFIXO)
	EndIf
	
	If lRet
		If FunName() = "G0112401"
			lRet := U_G0112411(SE2->E2_XENVEL,SE2->E2_NUM,SE2->E2_PREFIXO,2) //Grava Envelope na SE5 caso houver na SE2
		endif
	EndIf

	If lRet 	
		lRet := U_G0506803("M")
	EndIf

	If lRet //Validação para verificar se o contrato incluido está dentro das validações	
		lRet := U_G0108649()
	EndIf
	
	If lRet //Validação para verificar o centro de custo para titulos com grupo de natureza '3'	
		lRet := U_GTFIN032()
		If !lRet
			Return(lRet)
		Endif
	EndIf

Return lRet
