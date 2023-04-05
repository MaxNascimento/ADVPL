#INCLUDE "RWMAKE.ch"
#INCLUDE "TOTVS.CH"

User Function M020ALT()
	Local _aAmb := GetArea()
	Local lRet  := .T.
	
	//Integração Paradigma
	If FindFunction("U_FM020ALT")
        U_FM020ALT()
    EndIf

	U_F0410010() // Função que realiza o envio de fornecedores - INTEGRADO - ao eData - PostAddSupplier

	RestArea(_aAmb)
Return lRet
