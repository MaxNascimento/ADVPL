#Include 'Totvs.ch'
#Include 'TopConn.ch'

/*/
    Validação para preencher campo transportador
    @author Max Nascimento
    @since 04/11/2022
/*/

User Function GTFAT032()
    Local cEmit     := ""
    Local cTpVei    := ""
    Local cOrig     := ""
    LOcal cDest     := ""
    Local lRet      := .T.
	Local lRota     := .F.
	Local lTipo     := .F.
	Local dData     := Date()
	Local lFatByDAK := (FunName() == "MATA460B")

     //Chamada da função de controle de versao
	If FindFunction("VERSAOGT")
		SetKey(K_CTRL_F12, {||VERSAOGT()})
	Else
		SetKey(K_CTRL_F12, Nil)
	EndIf


    If !lFatByDAK

		//Dados logisticos
		cNumPed  := SC5->C5_NUM
    	cPedExp  := SC5->C5_PEDEXP
    	cTransp  := SC5->C5_TRANSP
    	cCliPed  := SC5->C5_CLIENT
    	cLojCli  := SC5->C5_LOJAENT
		cVeicul  := SC5->C5_VEICULO
		cTfrete  := SC5->C5_TPFRETE
	
	Else
		//CARGA

		//Dados logisticos
		cCdCarg  := DAK->DAK_COD
		cSeqCar  := DAK->DAK_SEQCAR
    	cTransp  := DAK->DAK_TRANSP
		cVeicul  := DAK->DAK_CAMINH
		cNumPed  := Posicione("DAI",1,FWxFilial("DAI")+cCdCarg+cSeqCar,"DAI_PEDIDO")
		cCliPed  := Posicione("DAI",1,FWxFilial("DAI")+cCdCarg+cSeqCar,"DAI_CLIENT")
		cLojCli  := Posicione("DAI",1,FWxFilial("DAI")+cCdCarg+cSeqCar,"DAI_LOJA")

	Endif

	if !Empty(cTransp) .and. cTfrete == 'C'


		//Codigo do Emitente
		DBSelectArea("GU3")
		DbSetOrder(13)
		DBSeek(xFilial("GU3")+cTransp)

    	cEmit := Alltrim(GU3->GU3_CDEMIT)
		
		//Tipo de veiculo
		DBSelectArea("DA3")
		DbSetOrder(1)
		DBSeek(xFilial("DA3")+cVeicul)
		
		cTpVei := DA3->DA3_TIPVEI

		//Cidade destino
		cUFDest  := Posicione("SA1",1,FWxFilial("SA1")+cCliPed+cLojCli,"A1_EST")
		cMun     := Posicione("SA1",1,FWxFilial("SA1")+cCliPed+cLojCli,"A1_COD_MUN")
		cMunDest := Posicione("CC2",1,FWxFilial("CC2")+cUFDest+cMun,"CC2_MUN")
		cDest 	 := Posicione("GU7",3,FWxFilial("GU7")+cMunDest+cUFDest,"GU7_NRCID")

		//Cidade origem
		DBSelectArea("SC6")
		SC6->(dbSetOrder(1))
       	 If SC6->(dbSeek(FWxFilial("SC6")+cNumPed))
			If !Empty(SC6->C6_XCDEMB) .AND. !Empty(SC6->C6_XLJEMB)
                cUFOrig  := Posicione("SA2",1,FWxFilial("SA2")+SC6->C6_XCDEMB+SC6->C6_XLJEMB,"A2_EST")
				cCodMun  := Posicione("SA2",1,FWxFilial("SA2")+SC6->C6_XCDEMB+SC6->C6_XLJEMB,"A2_COD_MUN")
				cMunOrig := Posicione("CC2",1,FWxFilial("CC2")+cUFOrig+cCodMun,"CC2_MUN")
				cOrig    := Posicione("GU7",3,FWxFilial("GU7")+cMunOrig+cUFOrig,("GU7_NRCID"))
			Endif	
		 Endif

	DbSelectArea("GVA")
		GVA->(DbSetOrder(1))
		if GVA->(DBSeek(xFilial("GVA")+cEmit))
			
 		 	While  cEmit == Alltrim(GVA->GVA_CDEMIT)
			if ((lRota) .and. (lTipo))
				exit
			elseif (!lRet)
				exit
			else

				DbSelectArea("GV9")
				GV9->(DbSetOrder(1))
       			if (DBSeek(xFilial("GV9")+cEmit))
				
					While  cEmit == Alltrim(GV9->GV9_CDEMIT)
					 	
							if ((lRota) .and. (lTipo))
								exit
							elseif (!lRota) .and. (lTipo)
								lRet := .F.
								Help(,,"GTFAT032",, "Faturamento " + IIF(!lFatByDAK,("do pedido "+cNumPed),"da carga "+cCdCarg) + " bloqueado devido a cidade Origem/Destino não estar cadastrada na rota da tabela de frete.", 1, 0,,,,,,{"Realize o cadastro da Rota na tabela de frete."})//ROTA NAO CADASTRADO
								Alert("Processo cancelado!")
								Break		
							elseif (!lTipo) .and. (lRota) 
								lRet := .F.
								Help(,,"GTFAT032",, "Faturamento " + IIF(!lFatByDAK,("do pedido "+cNumPed),"da carga "+cCdCarg) + " bloqueado devido o tipo de veiculo não estar cadastrado na Faixa da tabela de frete.", 1, 0,,,,,,{"Realize o cadastro da Faixa/Tipo Veiculo na tabela de frete."})//TIPO NAO CADASTRADO
								Alert("Processo cancelado!")
								Break	
							elseif (!lTipo) .and. (!lRota) .and. (!lRet)
							lRet := .F.
								Help(,,"GTFAT032",, "Faturamento " + IIF(!lFatByDAK,("do pedido "+cNumPed),"da carga "+cCdCarg) + " bloqueado devido o tipo de veiculo e a cidade Origem/Destino não estar cadastrado na tabela de frete.", 1, 0,,,,,,{"Realize o cadastro da Faixa/Tipo Veiculo e Rota na tabela de frete."})//TIPO e ROTA NAO CADASTRADO
								Alert("Processo cancelado!")
								Break
								exit
						
					else	
						if (dData < GV9->GV9_DTVALF)
													
							DbSelectArea("GV8")
							GV8->(DbSetOrder(1))
							if DBSeek(xFilial("GV8")+cEmit)
							
								While  cEmit == Alltrim(GV8->GV8_CDEMIT) .and. (!lRota)		
								
								cCidOrig := GV8->GV8_NRCIOR
								cRegOrig := GV8->GV8_NRREOR1
								cEstOrig := GV8->GV8_CDUFOR

								cCidDest := GV8->GV8_NRCIDS
								cRegDest := GV8->GV8_NRREDS
								cEstDest := GV8->GV8_CDUFDS

								if (GV8->GV8_TPORIG == '1') 
									if (cCidOrig == cOrig)
										if (GV8->GV8_TPDEST== '1') 
											if (cCidDest == cDest)
												lRota := .t.
												exit							
											endif
										elseif (GV8->GV8_TPDEST == '3')
											DbSelectArea("GUA")
											GUA->(DbSetOrder(1))
											if DBSeek(xFilial("GUA")+cRegDest+cDest)
												lRota := .t.
												exit
											endif
										elseif (GV8->GV8_TPDEST== '4')
											if (cEstDest == cUFDest)
												lRota := .t.
												exit
											endif
										else
										lRet := .t.
										endif									
									endif
								
								elseif (GV8->GV8_TPORIG == '3')
									DbSelectArea("GUA")
									GUA->(DbSetOrder(1))
									if DBSeek(xFilial("GUA")+cRegOrig+cOrig)
										if (GV8->GV8_TPDEST== '1') 
											if (cCidDest == cDest)
												lRota := .t.
												exit
											endif
										elseif (GV8->GV8_TPDEST == '3')
											DbSelectArea("GUA")
											GUA->(DbSetOrder(1))
											if DBSeek(xFilial("GUA")+cRegDest+cDest)
												lRota := .t.
												exit
											endif
										elseif (GV8->GV8_TPDEST== '4')
											if (cEstDest == cUFDest)
												lRota := .t.
												exit
											endif
										else
										lRet := .t.
										endif								
									endif
								
								elseif (GV8->GV8_TPORIG == '4')
									if (cEstOrig == cUFOrig)
										if (GV8->GV8_TPDEST== '1') 
											if (cCidDest == cDest)
												lRota := .t.
												exit
											endif
										elseif (GV8->GV8_TPDEST == '3')
											DbSelectArea("GUA")
											GUA->(DbSetOrder(1))
											if DBSeek(xFilial("GUA")+cRegDest+cDest)
												lRota := .t.
												exit
											endif
										elseif (GV8->GV8_TPDEST== '4')
											if (cEstDest == cUFDest)
												lRota := .t.
												exit
											endif
										else
										lRet := .t.
										endif	
									endif
									
								else
									if (GV8->GV8_TPDEST== '1') 
											if (cCidDest == cDest)
												lRota := .t.
												exit
											endif
										elseif (GV8->GV8_TPDEST == '3')
											DbSelectArea("GUA")
											GUA->(DbSetOrder(1))
											if DBSeek(xFilial("GUA")+cRegDest+cDest)
												lRota := .t.
												exit
											endif
										elseif (GV8->GV8_TPDEST== '4')
											if (cEstDest == cUFDest)
												lRota := .t.
												exit
											endif
										else
										lRet := .t.
										endif	
								endif

								GV8->(DbSkip())					
								EndDo

							
							else
							//NAO ROTA
							lRota := .F.
							endif


							DbSelectArea("GV7")
							GV7->(DbSetOrder(1))
							if DBSeek(xFilial("GV7")+cEmit)
							While  cEmit == Alltrim(GV7->GV7_CDEMIT) .and. (!lTipo)			   					
								if (cTpVei == Alltrim(GV7_CDTPVC))
									lTipo := .t.
									exit
								else
								lTipo := .f.
								endif
							GV7->(DbSkip())	
							EndDo
							else 
							lTipo := .f.
							endif												

							GV9->(DbSkip())

						else
						GV9->(DbSkip())
						endif
					Endif
					EndDo
				
			  	else
			   	Help(,,"GTFAT032",, "Faturamento do pedido " + cNumPed + " bloqueado devido a Negociação do Emitente não estar cadastrada na tabela de frete.", 1, 0,,,,,,{"Realize o cadastro da Negociação na tabela de frete."})//NAO EXISTE NEGOCIAÇÃO PARA EMITENTE
				lRet := .F.
				Break
			    endif	

            GVA->(DbSkip())
			Endif
    		EndDo
	 
		else
		Help(,,"GTFAT032",, "Faturamento do pedido " + cNumPed + " bloqueado devido o Emitente do transportador não estar cadastrada na tabela de frete.", 1, 0,,,,,,{"Realize o cadastro do Emitente na tabela de frete."})//NAO EXISTE EMITENTE
		lRet := .F.
		Break
		ENDIF	

   	Else 
		lRet := .T.
	Endif

Return lRet


Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)
	
	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL
	
	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10) 
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "001.0   MAX MIGUEL         130224    04/11/22 " + CHR(10) //Validação do campo transp
	@ 10,70 SAY oSay PROMPT "GTFAT031" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
		
	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
