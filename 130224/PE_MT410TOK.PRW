#Include "Totvs.ch"

/*/{Protheus.doc} MT410TOK
//P04007 - GAP031– Regras de Bloqueio de Pedidos na Inclusão
//Ponto de entrada antes da gravação do pedido de vendas
@type 		Function 
@author 	Sergio Compain
@since 		04/09/2019
@version 	P12.1.23
@project	0000032563
@history 	04/09/2019, Sergio Compain, Desenvolvimento inicial (P04007 - GAP031– Regras de Bloqueio de Pedidos na Inclusão)
/*/

User Function MT410TOK()
    Local lRet := .t.
    Local nOpc := paramixb[1]

	If Alltrim(FunName()) == "F0401320"
		Return(lRet)
	EndIf

	// GAP031– Regras de Bloqueio de Pedidos na Inclusão
    If lRet .and. (nOpc = 3 .or. nOpc = 4)
		lRet := U_F0400720(1,"FAT") 
		If !lRet
			Return(lRet)
		Endif
    EndIf

	//GAP 166 - COPIA DO PEDIDO DE VENDA
	if lRet
		lRet := U_G0116602()
		If !lRet
			Return(lRet)
		Endif
	EndIf
	
	If lRet	
		lRet := U_G0517803()
		If !lRet
			Return(lRet)
		Endif
	EndIf		

	//SM086_ID892	
	If lRet .and. nOpc = 3
		lRet := U_F0407020()
		If !lRet
			Return(lRet)
		Endif
	EndIf		

	If lRet .And. nOpc == 4 
		lRet := U_F0401328(nOpc) //Rotina para não permitir a alteração do pedido vindo da carga mae e filho	
		If !lRet
			Return(lRet)
		EndIf	
	EndIf

	If lRet 
		lRet := U_GTFAT031()
		If !lRet
			Return(lRet)
		Endif
	EndIf

Return(lRet)
