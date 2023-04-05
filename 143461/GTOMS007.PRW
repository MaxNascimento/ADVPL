/*/{Protheus.doc} GTOMS007
    (long_description)
    @type  Function
    @author user
    @since date
    @version version
    @param param, param_type, param_descr
    @return return, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function GTOMS007(aPedidos)

	Local cFLoren   	:= Alltrim(GetMV("FS_C040701", .T., "")) // filiais Lorenz
	Local aTotPed		:= {}
	Local lSC5Grv		:= .T.
    Local lFatByDAK     := .F.
	Local cUFOrig		:= ""
	Local cUFDest		:= ""
	Local lRet			:= .T.
    Local nX		    := 0
    Local nAlqICM	    := 0
	Local nTotPB	    := 0
	Local nPesRat	    := 0
	Local nValFrPd	    := 0
	Local nTotRat	    := 0
	Local nT		    := 0
	Local aPedFret	    := {}
	Local cPed		    := ""
    Private nVlrFret	:= 0
    Private cCarTran    := PARAMIXB[2][1][9]
    Private cCarVei     := PARAMIXB[2][1][10]
    Private cCarClFt    := PARAMIXB[2][1][26]
    Private cCarTpOp    := PARAMIXB[2][1][25]


    dbSelectArea("SC5")
    SC5->(DbSetOrder(1))
		For nX:= 1 to Len(aPedidos)

            cChavSC5 := aPedidos[nX][12]+aPedidos[nX][5]
            IF SC5->(DbSeek(cChavSC5)) 
                IF !(C5_FILIAL $ cFLoren) .AND. U_F0407011(lSC5Grv, @cUFOrig, @cUFDest) //Valida se o pedido está na regra para o frete autonomo
                    AaDd(aTotPed,cChavSC5)
                EndIf
            EndIF

        Next nX
   
    If Len(aTotPed) > 0

        nVlrFret := U_F0407021(.T.,lFatByDAK) // Calculo de frete autonomo. //- Ricardo

        //Valilda se o valor é maior que zero
        If nVlrFret > 0
            For nT := 1 To Len(aTotPed)	
                If cPed <> aTotPed[nT]
                    cPed := aTotPed[nT]
                    //Posiciona no pedido e busca a aliquota para efetuar o rateio por pedido
                    If SC5->( DbSeek(aTotPed[nT]) ) //DK1_FILPED+DK1_PEDIDO
                        //Pegando a aliquota
                        nAlqICM := U_F0407012(cUFOrig, cUFDest)
                        nTotPB	+= SC5->C5_PBRUTO

                        //Monta o array para gravar SC5 e efetuar o rateio por pedido
                        AaDd( aPedFret,{ SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_PBRUTO, nAlqICM } )
                    EndIf	
                EndIf	
            Next nT	

            //Quando for apenas 1 pedido
            If Len(aPedFret) == 1
                //Posiciona no pedido para realizar a gravação
                If SC5->(DbSeek(aPedFret[1][1]+aPedFret[1][2]))
                    nAlqICM := aPedFret[1][4]
                    SC5->( RecLock("SC5",.F.) )
                        SC5->C5_XVALFRE := nVlrFret
                        SC5->C5_XICMFRE	:= Round( nVlrFret*nAlqICM/100, 2)
                        SC5->C5_XAICFRE	:= nAlqICM
                    SC5->(MsUnlock())	
                EndIf
            Else
                For nX := 1 To Len(aPedFret)
                    //Posiciona no pedido para realizar a gravação
                    If SC5->(DbSeek(aPedFret[nX][1]+aPedFret[nX][2]))
                        nAlqICM 	:= aPedFret[1][4]
                        nPesRat		:= (aPedFret[nX][3]/nTotPB) // peso proporcional do rateio (%)
                        nValFrPd	:= Round(nPesRat*nVlrFret, 2)
                        nTotRat		+= nValFrPd

                        If nX == Len(aPedFret) // se for o último item, ajusta o valor residual
                            If nTotRat <> nVlrFret // se tem valor residual do rateio
                                nValFrPd := nValFrPd + (nVlrFret - nTotRat)
                            Endif
                        Endif

                        SC5->( RecLock("SC5",.F.) )
                            SC5->C5_XVALFRE := nValFrPd
                            SC5->C5_XICMFRE	:= Round( nValFrPd*nAlqICM/100, 2)
                            SC5->C5_XAICFRE	:= nAlqICM
                        SC5->(MsUnlock())
                    EndIf	
                Next nX	
            EndIf
        Else	
            Help( Nil, Nil, 'F0407020', Nil, "Faturamento do pedido " + SC5->C5_NUM + " bloqueado devido ao retorno do cálculo de frete autônomo estar sem valor", 1, 0, Nil, Nil, Nil, Nil, Nil, {""})
			Alert("Processo cancelado!")
			lRet := .F.
			Break
        EndIf
        
    EndIf


Return lRet
