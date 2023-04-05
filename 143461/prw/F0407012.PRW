#Include "Protheus.ch"

/*/{Protheus.doc} F0407012
Validação do icms frete.
@author Sergio Compain
@since 07/07/20
@project	0000032563

@history 	07/07/20, Sergio Compain, Desenvolvimento inicial (MIT044 – P04070 - SM086 - Cálculo de frete relacionado a despesas acessórias )
/*/

User Function F0407012(cUFOrig, cUFDest)

    Local nAliqIcm  := 0
    Local cIcmInt   := SuperGetMV("FS_C040851", .T., "") // SP12|SC17|MT17
    Local cUFNorte  := AllTrim(SuperGetMV("MV_NORTE" , .T., ""))
	Local aIcmInt	:= {}
	Local nPosUF	:= 0
	Local cUfICM	:= ""
	
    If cUFOrig == cUFDest // se for operação interna (SMI046)
		If (cUFDest $ cIcmInt) // Verificar se a UF de Destino está contida no parâmetro FS_C040851. Caso não, a aliq. é Zero -> benefício fiscal
			aIcmInt := StrTokArr(cIcmInt, "|")
			nPosUF  := aScan( aIcmInt, cUFDest )
			If nPosUF > 0
				cUfICM   := StrTran(aIcmInt[nPosUF], ",", ".") // caso tenha decimais
				nAliqIcm := Val(SubStr(cUfICM, 3, Len(cUfICM)))
			Endif
		Endif
    Else
        If cUFDest $ cUFNorte
            nAliqIcm := 7
        Else
            nAliqIcm := 12
        EndIf
    Endif

Return(nAliqIcm)
