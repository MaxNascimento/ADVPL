#Include 'Totvs.ch'
#Include 'TopConn.ch'

 /*/Importa arquivo de peso variavel e ajusta o pedido
@author Juliano Fregadolli
@since 30/05/2022
/*/
User Function GTOMS006()
	Local cPerg := "GTOMS006"
	Local cTitulo := "Importação do arquivo de peso variável"
	Private oGeraCsv

	// Montagem da tela de processamento.
	DEFINE MSDIALOG oGeraCsv TITLE cTitulo FROM 200,001 TO 580,580 PIXEL
	@ 02,10 TO 170,285 Pixel
	@ 10,018 Say " Este programa ira importar um arquivo Csv conforme layout   	" Pixel
	@ 18,018 Say " Definido pelo operador logístico                            	" Pixel
	@ 26,018 Say "                                                            	" Pixel

	SButton():New(155,188,1,{|| FwMsgRun(,{ || ExecProc() },'Importando','Importando arquivo...')})
	SButton():New(155,218,2,{|| oGeraCsv:End()})
	SButton():New(155,248,5,{|| Pergunte(cPerg,.T.)})

	Activate Dialog oGeraCsv Centered

Return .T.

Static Function ExecProc()
	Local aArea      := SC6->( GetArea() )
	Local cFilPed    := ""
	Local cArqCsv    := Alltrim(MV_PAR03)
	Local cCargaP    := Alltrim(MV_PAR01)
	Local cPedidoP   := Alltrim(MV_PAR02)
	Local nLeiaute   := MV_PAR04
	Local cBuffer    := ""
	Local cBuffAux	 := ""
	Local aProd  	 := {}
	Local aDados	 := {}
	Local aLinha 	 := {}
	Local aPedido    := {}
	Local aSaldQ     := {}
	Local cLinha 	 := ""
	Local cCarga     := ""
	Local cPedido    := ""
	Local dQtd       := ""
	Local cPedAnt    := ""
	Local cProd      := ""
	Local cItem      := ""
	Local cCliente   := ""
	Local cLoja      := ""
	Local cQtdLib    := ""
	Local nQtdTotal  := 0
	Local nVlrTotal  := 0
	Local cQuery     := ""
	Local cAlias	 := ""
	Local cCodCancao := ""
	Local cPlaca     := ""
	Local cData      := ""
	Local cNota      := ""
	Local k          := 0
	Local nQtdV		 := 0
	Local nQtdR		 := 0
	Local nQ		 := 0
	Local i          := 0
	Local j          := 0
	Local nI         := 0
	Local nPos       := 0
	Local nVlrPed    := 0
	Local nVlrLib    := 0
	Local lImport    := .T.

	If !File(cArqCsv)
		MsgAlert("Arquivo texto: " + cArqCsv + " não localizado", "ERRO")
		Return
	Endif

	FT_FUSE(cArqCsv)
	FT_FGOTOP()

	While !FT_FEOF()
		If Len(FT_FREADLN()) >= 1023
			cBuffAux := FT_FREADLN()
			FT_FSKIP()
		EndIf

		//Pula a 1a linha que é o cabecalho
		//FT_FSKIP()

		cBuffer := cBuffAux+FT_FREADLN()+";;;;;;;;;;;;;;;;;;;;;;;;;"+cLinha
		cBuffAux := ""
		aLinha := StrTokArr( replace(replace(replace(cBuffer,';;','; ;'),';;','; ;'),';;','; ;'), ";" )
		AADD(aDados,aLinha)
		FT_FSKIP()
	EndDo

	If nLeiaute = 2 //Barueri
		aDados := aSort(aDados,,,{|x,y| x[17]+x[09] < y[17]+y[09]})

		//Soma as quantidades dos itens
		For i:=1 To Len(aDados)
			cQtdLib := replace(Alltrim(aDados[i][19]), ',', '.')
			cPedido := SubStr(Alltrim(aDados[i][17]), 1, 6) + Alltrim(aDados[i][9]) //Pedido + produto
			cLinha  := ""

			If cPedAnt <> cPedido
				cPedAnt := cPedido
				k++

				For j:=1 To Len(aLinha)
					cLinha += aDados[i][j] + ";"
				Next j

				aLinha := StrTokArr(cLinha, ";")
				AADD(aProd,aLinha)
			Else
				dQtd := Val(replace(Alltrim(aProd[k][19]), ',', '.')) + Val(cQtdLib)
				aProd[k][19] := STR(dQtd)
			EndIf

		Next i
	else
		//Copia o array
		aProd := ACLONE(aDados)
	EndIf

	DBSelectArea("DAK")
	DBSetOrder(1)  //DAK_FILIAL+DAK_COD+DAK_SEQCAR

	DBSelectArea("DAI")
	DBSetOrder(4)  //DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR

	DBSelectArea("SC6")
	DBSetOrder(1)  //C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO

	DBSelectArea("SC9")
	DBSetOrder(2)  //C9_FILIAL+C9_CLIENTE+C9_LOJA+C9_PEDIDO+C9_ITEM

	For i:=1 To Len(aProd)
		If nLeiaute = 1  //APUCARANA E BEBEDOURO
			cCarga    := Alltrim(aProd[i][01])
			cPedido   := Alltrim(aProd[i][02])
			cCliente  := Alltrim(aProd[i][03])
			cLoja     := Alltrim(aProd[i][04])
			cProd     := Alltrim(aProd[i][08])
			cItem     := Alltrim(aProd[i][09])
			cQtdLib   := Alltrim(aProd[i][12])
			cFilPed   := FWCodFil()

			if (cFilPed == '01051') 
				//Busca o codigo do produto pelo codigo cancao
				cQuery	:= "SELECT SB1.B1_COD                            "
				cQuery	+= "  FROM " + RetSqlName("SB1") + " SB1         "
				cQuery	+= " WHERE SB1.B1_XCODCAN = '" + cProd + "' "
				cQuery	+= " 	AND SB1.B1_XPESVAR =  'S' 				 "
				cQuery	+= "   	AND SB1.D_E_L_E_T_ = ' '                 "

				cQuery	 := ChangeQuery(cQuery)
				cAlias	 := MPSysOpenQuery(cQuery)
				IF (cAlias)->(!EoF())
					cProd    := (cAlias)->B1_COD
					lImport  := .T.
				ELSE
					lImport := .F.
				ENDIF
			Endif

		elseif nLeiaute = 2  //BARUERI
			cPedido    := SubStr(Alltrim(aProd[i][17]), 1, 6)
			cCarga     := SubStr(Alltrim(aProd[i][17]), 8, 6)
			cQtdLib    := replace(Alltrim(aProd[i][19]), ',', '.')
			cCodCancao := Alltrim(aProd[i][9])
			cPlaca     := Alltrim(aProd[i][4])
			cData      := Alltrim(aProd[i][2])


			//Busca o codigo do produto pelo codigo cancao
			cQuery	:= "SELECT SB1.B1_COD                            "
			cQuery	+= "  FROM " + RetSqlName("SB1") + " SB1         "
			cQuery	+= " WHERE SB1.B1_XCODCAN = '" + cCodCancao + "' "
			cQuery	+= " 	AND SB1.B1_XPESVAR =  'S' 				 "
			cQuery	+= "   	AND SB1.D_E_L_E_T_ = ' '                 "

			cQuery	 := ChangeQuery(cQuery)
			cAlias	 := MPSysOpenQuery(cQuery)
			IF (cAlias)->(!EoF())
				cProd    := (cAlias)->B1_COD
				lImport  := .T.
			ELSE
				lImport := .F.
			ENDIF

			IF lImport
				//Ajusta formato da data
				cData   := SubStr(cData, 5, 4) + SubStr(cData, 3, 2) + SubStr(cData, 1, 2)

				//Busca cliente, loja e filial
				cQuery	:= "SELECT DAI.DAI_FILIAL, DAI.DAI_CLIENT, DAI.DAI_LOJA   "
				cQuery	+= "  FROM " + RetSqlName("DAK") + " DAK         "
				cQuery	+= "  JOIN " + RetSqlName("DAI") + " DAI ON DAI.DAI_FILIAL = DAK.DAK_FILIAL AND DAI.DAI_COD = DAK.DAK_COD AND DAI.D_E_L_E_T_ = ' '   "
				cQuery	+= " WHERE DAK.DAK_COD = '" + cCarga + "'        "
				cQuery	+= "   AND DAI.DAI_PEDIDO = '" + cPedido + "'     "
				cQuery	+= "   AND DAK.DAK_CAMINH = '" + cPlaca + "'     "
				// cQuery	+= "   AND DAK.DAK_DATA = '" + cData + "'        "      A DATA NAO VEM CORRETA NO ARQUIVO
				cQuery	+= "   AND DAK.D_E_L_E_T_ = ' '                  "

				cQuery	  := ChangeQuery(cQuery)
				cAlias	  := MPSysOpenQuery(cQuery)
				cCliente  := (cAlias)->DAI_CLIENT
				cLoja     := (cAlias)->DAI_LOJA
				cFilPed   := (cAlias)->DAI_FILIAL

				nPos := AScan(aPedido, {|x| AllTrim(Upper(x[1])) == cPedido .AND. ;
					AllTrim(Upper(x[2])) == cCliente .AND. AllTrim(Upper(x[3])) == cLoja })

				IF nPos == 0
					Aadd(aPedido, {cPedido , cCliente , cLoja, cFilPed})
				EndIf

				//Busca Item
				cQuery	:= "SELECT SC6.C6_ITEM, SC6.C6_NOTA  "
				cQuery	+= "  FROM " + RetSqlName("SC6") + " SC6      "
				cQuery	+= " WHERE SC6.C6_FILIAL = '" + cFilPed + "'  "
				cQuery	+= "   AND SC6.C6_NUM = '" + cPedido + "'     "
				cQuery	+= "   AND SC6.C6_PRODUTO = '" + cProd + "'   "
				cQuery	+= "   AND SC6.C6_CLI = '" + cCliente + "'    "
				cQuery	+= "   AND SC6.C6_LOJA = '" + cLoja + "'      "
				cQuery	+= "   AND SC6.D_E_L_E_T_ = ' '               "

				cQuery := ChangeQuery(cQuery)
				cAlias := MPSysOpenQuery(cQuery)
				cItem  := (cAlias)->C6_ITEM
			ENDIF

		EndIf

		IF lImport
			//Verifica se o pedido ja esta faturado
			cNota := Alltrim(Posicione("SC6",1,cFilPed+cPedido,"C6_NOTA"))

			If !Empty(cNota)
				MsgAlert("Pedido " + cPedido + " já está faturado!", "AVISO")
			Else
				nPos := AScan(aPedido, {|x| AllTrim(Upper(x[1])) == cPedido .AND. ;
					AllTrim(Upper(x[2])) == cCliente .AND. AllTrim(Upper(x[3])) == cLoja })

				IF nPos == 0
					Aadd(aPedido, {cPedido , cCliente , cLoja, cFilPed})
				EndIf

				If Empty(cPedidoP)
					If cCargaP == cCarga .and. VAL(cQtdLib) > 0 //Se a carga bater faz o corte da qtde de todos os pedidos
						If SC6->(DbSeek(AvKey(cFilPed,"C6_FILIAL") +   ;
								AvKey(cPedido,"C6_NUM") +      ;
								AvKey(cItem,"C6_ITEM") +       ;
								AvKey(cProd,"C6_PRODUTO")))

							cLocal := SC6->C6_LOCAL

							nPos := AScan(aSaldQ, {|x| AllTrim(Upper(x[2])) == cProd .AND. ;
								AllTrim(Upper(x[3])) == cLocal .AND. AllTrim(Upper(x[4])) == cPedido })

							IF nPos == 0
								Aadd(aSaldQ, {cFilPed , cProd , cLocal, cPedido})
							EndIf

							RecLock("SC6",.F.)
							SC6->C6_QTDLIB := VAL(cQtdLib)
							SC6->C6_QTDEMP := VAL(cQtdLib)
							SC6->(MsUnlock())
						Endif

						If SC9->(DbSeek(AvKey(cFilPed,"C9_FILIAL") +   ;
								AvKey(cCliente,"C9_CLIENTE") +   ;
								AvKey(cLoja,"C9_LOJA") +   ;
								AvKey(cPedido,"C9_PEDIDO") +   ;
								AvKey(cItem,"C9_ITEM")))
							RecLock("SC9",.F.)
							SC9->C9_QTDLIB := VAL(cQtdLib)
							SC9->(MsUnlock())
						Endif
					EndIf
				Else
					If cCargaP == cCarga .and. cPedidoP == cPedido .and. VAL(cQtdLib) > 0 //Se a carga e o pedido baterem faz o corte da qtde somente do pedido em questao
						If SC6->(DbSeek(AvKey(cFilPed,"C6_FILIAL") +   ;
								AvKey(cPedido,"C6_NUM") +      ;
								AvKey(cItem,"C6_ITEM") +       ;
								AvKey(cProd,"C6_PRODUTO")))

							cLocal := SC6->C6_LOCAL

							nPos := AScan(aSaldQ, {|x| AllTrim(Upper(x[2])) == cProd .AND. ;
								AllTrim(Upper(x[3])) == cLocal .AND. AllTrim(Upper(x[4])) == cPedido })

							IF nPos == 0
								Aadd(aSaldQ, {cFilPed , cProd , cLocal, cPedido})
							EndIf

							RecLock("SC6",.F.)
							SC6->C6_QTDLIB := VAL(cQtdLib)
							SC6->C6_QTDEMP := VAL(cQtdLib)
							SC6->(MsUnlock())
						Endif

						If SC9->(DbSeek(AvKey(cFilPed,"C9_FILIAL") +   ;
								AvKey(cCliente,"C9_CLIENTE") +   ;
								AvKey(cLoja,"C9_LOJA") +   ;
								AvKey(cPedido,"C9_PEDIDO") +   ;
								AvKey(cItem,"C9_ITEM")))
							RecLock("SC9",.F.)
							SC9->C9_QTDLIB := VAL(cQtdLib)
							SC9->(MsUnlock())
						Endif
					EndIf
				EndIf

				If DAI->(DbSeek(AvKey(cFilPed,"DAI_FILIAL") +   ;
						AvKey(cPedido,"DAI_PEDIDO") +      ;
						AvKey(cCarga,"DAI_COD") +      ;
						AvKey("01","DAI_SEQCAR")))

					//calcula a qtd total do pedido
					cQuery	:= "SELECT SUM(SC9.C9_QTDLIB) QTDTOT           "
					cQuery	+= "  FROM " + RetSqlName("SC9") + " SC9       "
					cQuery	+= " WHERE SC9.C9_FILIAL = '" + cFilPed + "'   "
					cQuery	+= "   AND SC9.C9_PEDIDO = '" + cPedido + "'   "
					cQuery	+= "   AND SC9.C9_CLIENTE = '" + cCliente + "' "
					cQuery	+= "   AND SC9.C9_LOJA = '" + cLoja + "'       "
					cQuery	+= "   AND SC9.D_E_L_E_T_ = ' '                "

					cQuery	:= ChangeQuery(cQuery)
					cAlias	:= MPSysOpenQuery(cQuery)
					nQtdTotal := (cAlias)->QTDTOT

					RecLock("DAI",.F.)
					DAI->DAI_PESO := nQtdTotal
					DAI->(MsUnlock())
				Endif

				If DAK->(DbSeek(AvKey(cFilPed,"DAK_FILIAL") +   ;
						AvKey(cCarga,"DAK_COD") +      ;
						AvKey("01","DAK_SEQCAR")))

					//calcula a qtd total da carga
					cQuery	:= "SELECT SUM(DAI.DAI_PESO) QTDTOT"
					cQuery	+= "  FROM " + RetSqlName("DAI") + " DAI "
					cQuery	+= " WHERE DAI.DAI_FILIAL = '" + cFilPed + "'"
					cQuery	+= "   AND DAI.DAI_COD = '" + cCarga + "'"
					cQuery	+= "   AND DAI.D_E_L_E_T_ = ' ' "

					cQuery	:= ChangeQuery(cQuery)
					cAlias	:= MPSysOpenQuery(cQuery)
					nQtdTotal := (cAlias)->QTDTOT

					//Calcula o valor total da carga
					cQuery	:= "SELECT SUM(VALOR) VTOTAL "
					cQuery	+= "  FROM (SELECT SC9.C9_QTDLIB * SC9.C9_PRCVEN VALOR "
					cQuery	+= "          FROM " + RetSqlName("SC9") + " SC9 "
					cQuery	+= "          JOIN " + RetSqlName("DAI") + " DAI ON DAI.DAI_FILIAL = SC9.C9_FILIAL AND DAI.DAI_PEDIDO = SC9.C9_PEDIDO AND DAI.DAI_CLIENT = SC9.C9_CLIENTE AND DAI.DAI_LOJA = SC9.C9_LOJA AND DAI.D_E_L_E_T_ = ' ' "
					cQuery	+= "         WHERE DAI.DAI_FILIAL = '" + cFilPed + "' "
					cQuery	+= "           AND DAI.DAI_COD = '" + cCarga + "' "
					cQuery	+= "           AND SC9.D_E_L_E_T_ = ' '"
					cQuery	+= "       ) "

					cQuery	:= ChangeQuery(cQuery)
					cAlias	:= MPSysOpenQuery(cQuery)
					nVlrTotal := (cAlias)->VTOTAL

					RecLock("DAK",.F.)
					DAK->DAK_PESO := nQtdTotal
					DAK->DAK_VALOR := nVlrTotal
					DAK->(MsUnlock())
				Endif
			EndIf
		EndIF
	Next i

	For nI := 1 To Len(aPedido)

		dbSelectArea("SA1")
		SA1->(dbSetOrder(1))
		SA1->(MsSeek( xFilial("SA1") + aPedido[nI][2] + aPedido[nI][3] ))

		aAreaSA1 := SA1->(GetArea())

		aPedSld := U_B0817002(aPedido[nI][2], aPedido[nI][3])

		IF LEN(aPedSld) > 0 .OR. LEN(aTitSld) > 0

		nVlrPed   := aPedSld[4]//SA1->A1_SALPED	    // Saldo de Pedidos
		nVlrLib  := aPedSld[3]//SA1->A1_SALPEDL	// Saldo Pedidos Liberados

			If !Empty(SA1->A1_COD)

				Reclock("SA1",.F.)

				SA1->A1_SALPED  := nVlrPed
				SA1->A1_SALPEDL := nVlrLib
				
				SA1->(MsUnlock())

			EndIf

		ENDIF

		DbSelectArea("SC5")
		DbSetOrder(3)

		If SC5->(DbSeek(AvKey(aPedido[nI][4],"C5_FILIAL") + AvKey(aPedido[nI][2],"C5_CLIENTE") + ;
				AvKey(aPedido[nI][3],"C5_LOJA") + AvKey(aPedido[nI][1],"C5_NUM") ))

			RecLock("SC5",.F.)

			SC5->C5_LIBEROK := " "

			SC5->(MsUnlock())
		Endif

	Next nI

	For nQ := 1 To Len(aSaldQ)

		cQuery	:= " SELECT SUM(C9_QTDLIB) QTDLIB "
		cQuery	+= " 	FROM " + RetSqlName("SC9") + " SC9 "
		cQuery	+= " 		JOIN " + RetSqlName("SB2") + " SB2 "
		cQuery	+= " 		ON SC9.C9_FILIAL = SB2.B2_FILIAL "
		cQuery	+= " 		AND SC9.C9_PRODUTO = SB2.B2_COD "
		cQuery	+= " 		AND SC9.C9_LOCAL = SB2.B2_LOCAL "
		cQuery	+= " 		AND SB2.D_E_L_E_T_ = ' ' "
		cQuery	+= "	 WHERE SC9.C9_PRODUTO = '" + aSaldQ[nQ][2] + "' "
		cQuery	+= " 		AND SC9.C9_LOCAL = '" + aSaldQ[nQ][3] + "' "
		cQuery	+= " 		AND SC9.C9_FILIAL = '" + aSaldQ[nQ][1] + "' "
		cQuery	+= " 		AND SC9.C9_NFISCAL = ' ' "
		cQuery	+= "		AND SC9.C9_OK = ' ' "
		cQuery	+= " 		AND SC9.D_E_L_E_T_ = ' ' "

		cQuery	:= ChangeQuery(cQuery)
		cAlias	:= MPSysOpenQuery(cQuery)
		nQtdR := (cAlias)->QTDLIB

		cQuery	:= " SELECT SUM(C6_QTDVEN) QTDVEN "
		cQuery	+= " 	FROM " + RetSqlName("SC6") + " SC6 "
		cQuery	+= " 		WHERE SC6.C6_PRODUTO = '" + aSaldQ[nQ][2] + "' "
		cQuery	+= " 			AND SC6.C6_LOCAL = '" + aSaldQ[nQ][3] + "' "
		cQuery	+= " 			AND SC6.C6_FILIAL = '" + aSaldQ[nQ][1] + "' "
		cQuery	+= " 			AND SC6.C6_NOTA = ' ' "
		cQuery	+= " 			AND SC6.D_E_L_E_T_ = ' ' "
		cQuery	+= " 			AND SC6.C6_BLQ = ' ' "
		cQuery	+= " 			AND SC6.D_E_L_E_T_ = ' ' "

		cQuery	:= ChangeQuery(cQuery)
		cAlias	:= MPSysOpenQuery(cQuery)
		nQtdV := (cAlias)->QTDVEN - nQtdR

		DbSelectArea("SB2")
		DbSetOrder(1)

		If SB2->(DbSeek(AvKey(aSaldQ[nQ][1],"B2_FILIAL") + AvKey(aSaldQ[nQ][2],"B2_COD") + ;
				AvKey(aSaldQ[nQ][3],"B2_LOCAL") ))

			RecLock("SB2",.F.)

			SB2->B2_QPEDVEN := nQtdV
			SB2->B2_RESERVA := nQtdR

			SB2->(MsUnlock())
		Endif

	Next nQ

	DAK->(DbCloseArea())
	DAI->(DbCloseArea())
	SC6->(DbCloseArea())
	SC9->(DbCloseArea())
	SA1->(DbCloseArea())
	SC5->(DbCloseArea())
	SB2->(DbCloseArea())



	RestArea(aArea)
	MsgAlert("Processo finalizado!", "AVISO")

Return .T.

Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)

	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL

	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10)
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "005.1   MAX NASCIMENTO      148852  24/03/23 " + CHR(10) //Ajuste no Layout para adequação da filial de Bebedouro
	cTexto += "004.2   FABIANE GORRI       138365  29/12/22 " + CHR(10) //Inclusão de tratamento do valor liberado por pedido no cadastro do PRODUTO SB2
	cTexto += "004.1   FABIANE GORRI       138365  21/12/22 " + CHR(10) //Validação para não importar quando o produto não for Peso Variavel - Barueri
	cTexto += "004.0   FABIANE GORRI       138365  20/12/22 " + CHR(10) //Inclusão de tratamento do valor liberado por pedido no cadastro do cliente - Legenda Pedido
	cTexto += "003.2   FREGADOLLI          138365  23/11/22 " + CHR(10) //Inclusao: pedido faturado, data lote, qtde empenho, soma qtd
	cTexto += "003.1   FREGADOLLI          138365  08/11/22 " + CHR(10) //Ajuste da virgula no campo C6_QTDLIB
	cTexto += "003.0   FREGADOLLI          138365  21/10/22 " + CHR(10) //Considerar somente produto de peso variavel
	cTexto += "002.0   FREGADOLLI          135053  19/09/22 " + CHR(10) //Incluido novo leiaute
	cTexto += "001.0   FREGADOLLI          135732  09/09/22 " + CHR(10) //Incluido tratamento de cabecalho e depois retirado, mantido comentado

	@ 10,70 SAY oSay PROMPT "GTOMS006" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
