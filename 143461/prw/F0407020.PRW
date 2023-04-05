#Include "TOTVS.ch"

/*/{Protheus.doc} F0407020
description
@type function
@version 
@author Sergio
@since 10/08/2020
@return return_type, return_description
/*/
User Function F0407020()

    Local lRet      := .t.
    Local cFLoren   := Alltrim(GetMV("FS_C040701", .T., "")) // filiais Lorenz
    Local nValFre   := 0
    Local nAICFre   := 0
	Local nIcmFre   := 0
	Local lSC5Grv	:= .F.
	Local cUFOrig	:= ""
	Local cUFDest	:= ""

    If !Alltrim(Funname()) $ "OGA250|OGA 251"
        Return(.T.)
    EndIf
    
    // MIT044 – P04070 - SM086 - Cálculo de frete relacionado a despesas acessórias
    If !FwxFilial("SC5") $ cFLoren

        If U_F0407011(lSC5Grv, @cUFOrig, @cUFDest) // //Valida se o pedido está na regra para o frete autonomo
            nValFre := U_F0407021(.F., .F.) // Calculo de frete autonomo. //- Ricardo
            If nValFre <= 0
                lRet := .f.
                Help( Nil, Nil, 'F0407020', Nil, "Geração do pedido " + M->C5_NUM + " não gerado devido ao retorno do cálculo de frete autônomo estar sem valor", 1, 0, Nil, Nil, Nil, Nil, Nil, {""})
            Else
			    nAICFre := U_F0407012(cUFOrig, cUFDest) // icms frete
				nIcmFre := Round(((nValFre * nAICFre) / 100),2)
            EndIf
        EndIf

		M->C5_XVALFRE := nValFre
		M->C5_XAICFRE := nAICFre
		M->C5_XICMFRE := nIcmFre

    EndIf

Return(lRet)
