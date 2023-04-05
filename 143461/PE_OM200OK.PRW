#Include "Protheus.ch"
#Include "TopConn.ch"
#Define QUE_LIN  Chr(13)+Chr(10)
 
User Function OM200OK()
	Local aPedidos := PARAMIXB[01]
	Local lRet := .T.

	If FindFunction("U_F0404604")
		lRet := U_F0404604(aPedidos)
	Endif

	If FindFunction("U_GTOMS007")
		lRet := U_GTOMS007(aPedidos)
	Endif
	
Return lRet
