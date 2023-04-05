#INCLUDE 'Totvs.CH'

/*/{Protheus.doc} F0407010
//Rotina de validação dos pedidos na DK1 e regra de frete autonomo.
@author    Ronaldo Dantas
@since     06/07/20
@project   0000032563
@history 
/*/
User Function F0407010(aParam, cErro)

    //Declarando variáveis
	Local aAreaDK1		:= DK1->( GetArea() )
	Local aAreaSC5		:= SC5->( GetArea() )
    Local cCodViag		:= aParam[1] //DK0_VIAGID
	Local cCodRegi		:= aParam[4] //DK0_REGID
	Local cFilLorenz	:= GetMv("FS_C040701")//SuperGetMv("FS_C040701",.T.,"")
	Local aTotPed		:= {}
	Local bPosVld		:= {|| Positivo() }
	Local lSC5Grv		:= .T.
	Local cUFOrig		:= ""
	Local cUFDest		:= ""
	Local lRet			:= .T.

	Private cPict		:= PesqPict("SC5","C5_XVALFRE")
	Private cF3			:= ""	
	Private lRetPE 		:= .T.
	Private nVlrFret	:= 0
	Private cChavDk1	:= ""
	Private oTelaPr
	Private oGetPr
	Private oBtnConf
	Private oBtnCanc	
	Private cErroPE		:= ""
	
	cErro := ""

	DK1->(dbSetOrder(1))
	If DK1->(dbSeek(xFilial("DK1")+	cCodRegi+cCodViag)) //DK1_FILIAL+DK1_REGID+DK1_VIAGID
		SC5->(DbSetOrder(1))
		While DK1->(!Eof()) .AND. xFilial("DK1") == DK1->DK1_FILIAL .AND. DK1->DK1_REGID == cCodRegi .AND. DK1->DK1_VIAGID == cCodViag
			cChavDk1 := DK1->DK1_FILPED+DK1->DK1_PEDIDO
			//Posiciona no pedido vinculado a viagem
			IF SC5->(DbSeek(cChavDk1)) //DK1_FILPED+DK1_PEDIDO
				IF DK1->DK1_FILPED $ cFilLorenz .AND. U_F0407011(lSC5Grv, @cUFOrig, @cUFDest) //Valida se o pedido está na regra para o frete autonomo
					AaDd(aTotPed,cChavDk1)
				EndIf
			EndIF
			DK1->(DbSkip())
		EndDo

		//Abre a tela para digitar o valor do frete autonomo caso os pedidos estiverem na regra.
		If Len(aTotPed) > 0
			oTelaPr 	:= MSDialog():New( 092,232,180,603,"Valor do Frete Autonomo",,,.F.,,,,,,.T.,,,.T. )
			oGetPr		:= TGet():New( 004,003,{|u| If(PCount()>0,nVlrFret:=u,nVlrFret)},oTelaPr ,176,008,cPict,bPosVld,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,cF3,"nVlrFret",,,,.F.,.T.,.T.,"Valor do frete",1 )
			oBtnConf	:= TButton():New( 024,103,"&Confirmar",oTelaPr,{|| fConfirm(cCodRegi, cCodViag, aTotPed, cUFOrig, cUFDest)},037,012,,,,.T.,,"",,,,.F. )
			oBtnCanc	:= TButton():New( 024,142,"&Cancelar",oTelaPr,{||fCancela()},037,012,,,,.T.,,"",,,,.F. )

			oTelaPr:lEscClose	:= .F. 
			oTelaPr:lCentered	:= .T.
			oTelaPr:Activate(,,,.T.)	
		EndIf
	EndIF

	RestArea(aAreaSC5)
	RestArea(aAreaDK1)

	lRet 	:= lRetPE 
	cErro	:= cErroPE
	
Return lRet


/*/{Protheus.doc} fConfirm(cCodRegi,cCodViag)
//Rotina de confirmação e gravação no botão confirmar da msdialog                                                 
| Autor: Ronaldo Dantas                                             
| Data:  07/07/2020                                                 
| Desc:  Função de confirmação da rotina                            
| Obs.:                                                            
/*/
Static Function fConfirm(cCodRegi, cCodViag, aTotPed, cUFOrig, cUFDest)

	Local nAlqICM	:= 0
	Local nTotPB	:= 0
	Local nPesRat	:= 0
	Local nValFrPd	:= 0
	Local nTotRat	:= 0
	Local nX		:= 0
	Local nT		:= 0
	Local aPedidos	:= {}
	Local cPed		:= ""
	Local cMsg		:= ""

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
					AaDd( aPedidos,{ SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_PBRUTO, nAlqICM } )
				EndIf	
			EndIf	
		Next nT	

		//Quando for apenas 1 pedido
		If Len(aPedidos) == 1
			//Posiciona no pedido para realizar a gravação
			If SC5->(DbSeek(aPedidos[1][1]+aPedidos[1][2]))
				nAlqICM := aPedidos[1][4]
				SC5->( RecLock("SC5",.F.) )
					SC5->C5_XVALFRE := nVlrFret
					SC5->C5_XICMFRE	:= Round( nVlrFret*nAlqICM/100, 2)
					SC5->C5_XAICFRE	:= nAlqICM
				SC5->(MsUnlock())	
			EndIf
		Else
			For nX := 1 To Len(aPedidos)
				//Posiciona no pedido para realizar a gravação
				If SC5->(DbSeek(aPedidos[nX][1]+aPedidos[nX][2]))
					nAlqICM 	:= aPedidos[1][4]
					nPesRat		:= (aPedidos[nX][3]/nTotPB) // peso proporcional do rateio (%)
					nValFrPd	:= Round(nPesRat*nVlrFret, 2)
					nTotRat		+= nValFrPd

					If nX == Len(aPedidos) // se for o último item, ajusta o valor residual
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
		oTelaPr:End()	
	Else	
		cMsg := "O valor do frete autônomo deve ser informado para a viagem " + DK1->DK1_VIAGID
	EndIf

	If !Empty(cMsg)
		lRetPE	:= .F.
		cErroPE	:= cMsg
		
		oGetPr:Refresh()
	EndIf	
	
Return

/*/{Protheus.doc} fCancela()
//Rotina de cancelamento do botão cancelar da msdialog                                                
| Autor: Ronaldo Dantas                                               
| Data:  07/07/2020                                                   
| Desc:  Função de cancelamento da rotina                             
| Obs.:                                                             
/*/
Static Function fCancela()
	//Setando o retorno em branco e finalizando a tela
	lRetPE 		:= .F.
	cErroPE 	:= "Valor do frete autônomo não informado!"
	
	nVlrFret	:= 0
	oTelaPr:End()
Return 