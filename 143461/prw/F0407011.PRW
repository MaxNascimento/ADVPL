#Include "Protheus.ch"

/*/{Protheus.doc} F0407011
Validação do frete.
@author Sergio Compain
@since 07/07/20
@project	0000032563

@history 	07/07/20, Sergio Compain, Desenvolvimento inicial (MIT044 – P04070 - SM086 - Cálculo de frete relacionado a despesas acessórias )
/*/

User Function F0407011(lSC5Grv, cUFOrig, cUFDest)

    Local aAreaSC6 := {}
    Local cFSOrig  := Alltrim(SuperGetMV("FS_C040703", .T., "")) // UFs de Origens que fazem parte do processo de cálculo de frete
    Local cUFTran  := ""    
    Local cNumPed  := ""
    local aEmpInfo := FWSM0Util():GetSM0Data( cEmpAnt ,cFilAnt , { "M0_ESTCOB" } )
    Local cUFFil   := iif(len(aEmpInfo)>0, alltrim(aEmpInfo[1][2]), "")
    Local lRet     := .f.
    Local lUFOrig  := .t.
    Local lUFTran  := .t.
	Local cPedExp  := ""
    Local cTpFrete := ""
    Local cTransp  := ""
    Local cCliPed  := ""
    Local cLojCli  := ""
    Local cTipo    := ""
    Local nX       := 0
	Local nPXCDEMB := 0
	Local nPXLJEMB := 0
    Local lSair    := .F.
	
    Local lCFOP	   := .T.

    //Local cCFOPFat := Alltrim(SuperGetMV("FS_C040761", .T., "")) // CFOP’s referentes a pedido de venda (Faturamento) no processo de venda conta e ordem
    Local cCFOPFre := Alltrim(SuperGetMV("FS_C040111", .T., "")) // CFOP’s referentes ao calculo do frete autonomo
	Local nPosCF   := 0
    Local nPCONTRA := 0
	Local cCFOPIt  := ""
	Local cIcmInt  := SuperGetMV("FS_C040851", .T., "") // SP12|SC17|MT17
	
    Default  lSC5Grv := .T.

    cUFOrig  := ""
    cUFDest  := ""

    If lSC5Grv
        cNumPed  := SC5->C5_NUM
        cPedExp  := SC5->C5_PEDEXP
        cTpFrete := SC5->C5_TPFRETE
        cTransp  := SC5->C5_TRANSP
        cCliPed  := SC5->C5_CLIENT
        cLojCli  := SC5->C5_LOJAENT
        cTipo    := SC5->C5_TIPO
    Else
        cNumPed  := M->C5_NUM
        cPedExp  := M->C5_PEDEXP
        cTpFrete := M->C5_TPFRETE
        cTransp  := M->C5_TRANSP
        cCliPed  := M->C5_CLIENT
        cLojCli  := M->C5_LOJAENT
        cTipo    := M->C5_TIPO
	    nPXCDEMB := Ascan(aHeader, {|x| Alltrim(X[2]) == "C6_XCDEMB"})
	    nPXLJEMB := Ascan(aHeader, {|x| Alltrim(X[2]) == "C6_XLJEMB"})
		nPosCF	 := Ascan(aHeader, {|x| Alltrim(x[2]) == "C6_CF"})
        nPCONTRA := Ascan(aHeader, {|x| Alltrim(x[2]) == "C6_CONTRAT"})
    EndIf

    If !Empty(cPedExp)
        Return(lRet)
    EndIf

    If Empty(cFSOrig)
        Return(lRet)
    EndIf

	// Tipo de Frete dever ser CIF (GTFOODS realiza o pagamento C ou R)
    If !(cTpFrete $ "CR") // C=CIF;F=FOB;T=Por conta terceiros;R=Por conta remetente;D=Por conta destinatário;S=Sem frete                                    
        Return(lRet)
    EndIf

    cUFTran  := Posicione("SA4",1,FWxFilial("SA4")+cTransp,"A4_EST")

    If !cTipo $ "DB"
        cUFDest :=  Posicione("SA1",1,FWxFilial("SA1")+cCliPed+cLojCli,"A1_EST")
    Else
        cUFDest :=  Posicione("SA2",1,FWxFilial("SA2")+cCliPed+cLojCli,"A2_EST")
    EndIf

    If lSC5Grv 
        aAreaSC6 := SC6->(Getarea())

        SC6->(dbSetOrder(1))
        If SC6->(dbSeek(FWxFilial("SC6")+cNumPed))
            While SC6->(!Eof() .and. SC6->C6_FILIAL == FWxFilial("SC6") .and. SC6->C6_NUM == cNumPed)
                If !Empty(SC6->C6_XCDEMB) .AND. !Empty(SC6->C6_XLJEMB)
                    cUFOrig := Posicione("SA2",1,FWxFilial("SA2")+SC6->C6_XCDEMB+SC6->C6_XLJEMB,"A2_EST")
                    If Empty(cUFOrig)
                        cUFOrig := cUFFil
                        lSair   := .T.
                    EndIf    
                Else
                    cUFOrig := cUFFil
                EndIf

                If !cUFOrig $ cFSOrig
                    lUFOrig := .f.
                    Exit
                EndIf

                If cUFTran == cUFOrig
                    lUFTran := .f.
                    Exit
                EndIf
                
                //Verifica se o pedido de venda possui contrato de parceira para depois validar o CFOP
				If !Empty(SC6->C6_CONTRAT) .And. !Empty(cCFOPFre) // CFOPs para calculo do frete autonomo.
					cCFOPIt := SC6->C6_CF // CFOP do item do pedido
					If !(Alltrim(cCFOPIt) $ Alltrim(cCFOPFre))
						lCFOP := .f.
						Exit
					Endif
				Endif
                
                If lSair  
                    EXIT
                Endif

                SC6->(dbSkip())
            End
        EndIf
        
        RestArea(aAreaSC6)
    Else
        For nX := 1 to len(aCols)
            If !Empty(aCols[nX][nPXCDEMB]) .AND. !Empty(aCols[nX][nPXLJEMB])
                cUFOrig := Posicione("SA2",1,FWxFilial("SA2")+aCols[nX][nPXCDEMB]+aCols[nX][nPXLJEMB],"A2_EST")
                If Empty(cUFOrig)
                   cUFOrig := cUFFil
                   lSair   := .T.
                EndIf    
            Else
               cUFOrig := cUFFil
            EndIf

            If !cUFOrig $ cFSOrig
                lUFOrig := .f.
                Exit
            EndIf

            If cUFTran == cUFOrig
                lUFTran := .f.
                Exit
            EndIf
			
            //Verifica se o pedido de venda possui contrato de parceira para depois validar o CFOP
			If !Empty(aCols[nX][nPCONTRA]) .And. !Empty(cCFOPFre) // CFOPs para calculo do frete autonomo.
				cCFOPIt := aCols[nX][nPosCF] // CFOP do item do pedido C6_CF
				If !(Alltrim(cCFOPIt) $ Alltrim(cCFOPFre))
					lCFOP := .f.
					Exit
				Endif
			Endif
			
            If lSair  
                EXIT
            Endif
        Next nX
    EndIf

    If lUFOrig .and. lUFTran .and. lCFOP
        lRet := .t.
    EndIf  

	If lRet
		If cUFOrig == cUFDest // se for operação interna (SMI046)
			If !(cUFDest $ cIcmInt) // Verificar se a UF de Destino está contida no parâmetro FS_C040851. Caso não, a aliq. é Zero -> benefício fiscal
				lRet := .F.					
			Endif
		Endif
	Endif

    aSize(aEmpInfo,0)
Return(lRet)
