#Include 'Totvs.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} F0401501
Rotina para geração de arquivo txt conforme layout do operador.
@author 	Ronaldo Dantas
@since 		11/10/2019
@version 	12.1.23
@type 		Function
@project 	0000032563
@history 	Desenvolvimento inicial (MIT044 - P04015 - GAP137 - Integração WMS Terceiro X Protheus)
/*/
User function F0401501()

	// Declaração das variáveis
    Local cPerg 		:= "FSW0401501"
                                           
    Private oGeraCsv
 
    // fCriaSX1(cPerg)    
    //Pergunte(cPerg,.F.)

    // Montagem da tela de processamento.
    DEFINE MSDIALOG oGeraCsv TITLE "Geração de arquivo Csv para operador logistica" FROM 200,001 TO 580,580 PIXEL
    @ 02,10 TO 170,285 Pixel
    @ 10,018 Say " Este programa ira gerar um arquivo Csv conforme layout   	" Pixel
    @ 18,018 Say " Definido pelo operador logístico                            	" Pixel
    @ 26,018 Say "                                                            	" Pixel

	SButton():New(155,188,1,{|| FwMsgRun(,{ || fProc() },'Processamento Relatório','Gerando arquivo...')})
    SButton():New(155,218,2,{|| oGeraCsv:End()})
    SButton():New(155,248,5,{|| Pergunte(cPerg,.T.)})

    Activate Dialog oGeraCsv Centered

Return

/*/{Protheus.doc} fProc
Rotina executa a query com os pedidos baseado no local conforme layout definido no parametro de pergunta.
@author 	Ronaldo Dantas
@since 		11/10/2019
@version 	12.1.23
@type 		Function
@param 		mvpar, characters, conforme informado pelo usuário.
/*/
Static Function fProc()

    Local aAreaNNR  := NNR->(GetArea())
	Local aAreaSB1  := SB1->(GetArea())
	Local aAreaDAI  := DAI->(GetArea())
	Local aAreaDAN  := DAN->(GetArea())
	Local aAreaSA1  := SA1->(GetArea())
	Local aAreaSC5  := SC5->(GetArea())
    Local aLayout   := {}
	Local aRows		:= {}
	Local aRel		:= {}

	Local lRet		:= .F.

	Local cNomeArq  := DToS(DDatabase) + STRTRAN(TIME(),":","") 
	Local cRelTit	:= "Relatório de Separação"
    Local cQuery    := ""
    Local cLayout   := ""
	Local cCgcEmit	:= ""
	Local cNomeEmit	:= ""
	Local cNome		:= ""
	Local cArqCsv	:= "" 
	Local cRow      := ""
	Local cCab      := ""
	Local cAlias	:= ""
	Local cClient	:= ""
	Local cEnd		:= ""
	Local cBairro	:= ""
	Local cCep		:= ""
	Local cMum		:= ""
	Local cUf		:= ""
	Local cCgcDes	:= ""
	Local cIe		:= "" 
	Local cCompl	:= ""
	Local cCodMun	:= ""
	Local cFone		:= ""
	Local cCodCarg	:= ""
	Local cCodVei	:= ""	
	Local cItCarga	:= ""
	Local cSeqCar	:= ""
	Local cSeq		:= ""
	Local cTpFrete	:= ""
	Local cPed		:= ""
	Local cNota		:= ""
	Local cSerie	:= ""

	Local nHld		:= 0
	Local nX		:= 0
	Local nT		:= 0
	Local nQuant	:= 0
	Local nValor	:= 0
	Local nPeso		:= 0
	Local nItens	:= 0
	Local cLocArq	:= Alltrim(mv_par04)
	Local cFilArFr	:= ""
	Local cFilMarc  := SuperGetMV( "FS_C040152", .F., "", cFilAnt)// Para item de terceiro -> parâmetro exclusivo por filial
	Local cFilPes   := SuperGetMV( "FS_C040153", .F., "" )//Filiais para gerar arquivo com e sem peso variável
	Local nPesoProd	:= 0
	Local cCarga	:= ""
	Local cCargaAnt	:= ""
	Local dDtCar	:= Ctod("//")
	Local nTtPeso	:= 0
	Local nTtPesoB 	:= 0
	Local nPesoBru	:= 0
	Local cProdPlac	:= ""

	Local cDes3Prod := ""
	Local nQtd3Prod	:= 0
	Local nVlr3Prod	:= 0
	Local nPes3Prod	:= 0
	Local cPla3Prod	:= ""
	Local cPro3Prod	:= ""
	Local nVol3Prod	:= 0
	Local nU		:= 0
	Local nPes3Uni	:= 0
	Local nUIni		:= 0
	local aEmpInfo := FWSM0Util():GetSM0Data( cEmpAnt ,cFilAnt , { "M0_FILIAL" , "M0_CGC", "M0_NOMECOM","M0_ENDENT", "M0_BAIRENT", "M0_CEPENT", "M0_CIDENT","M0_ESTENT" } )
	local nPosNome  := aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_NOMECOM"})
	local nPosFil   := aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_FILIAL"})
	local nPosCgc   := aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_CGC"})
	local nPosEnd   := aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_ENDENT"})
	local nPosBairro:= aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_BAIRENT"})
	local nPosCep   := aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_CEPENT"})
	local nPosCid   := aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_CIDENT"})
	local nPosEst   := aScan(aEmpInfo, {|aFields| alltrim(aFields[1]) == "M0_ESTENT"})
	
	cClient		:= aEmpInfo[nPosNome][2]
	cEnd		:= aEmpInfo[nPosEnd][2]
	cBairro		:= aEmpInfo[nPosBairro][2]
	cCep		:= Transform(aEmpInfo[nPosCep][2], "@R 99999-999")   
	cMum		:= aEmpInfo[nPosCid][2]
	cUf			:= aEmpInfo[nPosEst][2]
	cCgcEmit	:= aEmpInfo[nPosCgc][2]
	cNomeEmit	:= aEmpInfo[nPosFil][2]


    cLayout := Posicione("NNR",1,FWxFilial("NNR") + MV_PAR01,"NNR_XOPLOG") // 1=AirFrio;2=ComFrio;3=UniFrango;4=ViFrio;5=EngeCompany
	IF Empty(cLayout)
		MsgAlert("Não existe layout informado no campo NNR_XOPLOG para o local de estoque "+MV_PAR01 )
		Return 
	Endif

	cQuery	:= " SELECT "
	cQuery	+= "		C6_FILIAL FIL_CLIENTE, "
	cQuery	+= "		C9_NFISCAL NF, " 
	cQuery	+= " 		C9_SERIENF SERIE, "
	cQuery	+= "		' ' CLIENTE, "
	cQuery	+= "		' ' CIDADE, "
	cQuery	+= "		' ' UF, " 
	cQuery	+= " 		B1_XCODCAN SKU, "
	cQuery	+= "		C6_DESCRI DESCRICAO, "
	cQuery	+= "		C9_QTDLIB QUANT, "
	cQuery	+= "		' ' BAIRRO, "
	cQuery	+= "		' ' DATA_PRD, "
	cQuery	+= "		B1_CONV FAIXA, "
	cQuery	+= "		' ' ORDENT, "
	cQuery	+= "		' ' LOTE, "
	cQuery	+= "		C6_PRODUTO PRODUTO, "
	cQuery	+= " 		C6_PRCVEN V_UNITARIO, "
	cQuery	+= "		C6_VALOR V_TOTAL, "
	cQuery	+= "		C6_CLI CLIENT, "
	cQuery	+= "		C6_LOJA LOJA, "
	cQuery	+= "		C6_NUM NUM_PEDIDO, "
	cQuery	+= "		C5_EMISSAO DATA_PEDIDO, "
	cQuery	+= "		C5_PESOL PESO_LIQ_PEDIDO, " 
	cQuery	+= " 		C5_PBRUTO PESO_BRUTO, "
	cQuery	+= "		C9_LOTECTL NUM_LOTE, "
	cQuery	+= "		C6_ENTREG DATA_ENT, "
	cQuery	+= "		C6_ITEM ITEM, "
	cQuery	+= "		B1_PESO PESO, "
	cQuery	+= "		C6_SERIE, "
	cQuery	+= "		C9_QTDLIB2 QUANT2, "
	cQuery	+= "		C5_TIPO, "
	cQuery	+= "		C5_VEND1, "
	cQuery	+= "		C5_XFORMA, "
	cQuery	+= "		C6_ENTREG, "
	cQuery	+= "		C6_SUGENTR, " 
	cQuery	+= " 		C5_TPFRETE TPFRETE, "
	cQuery	+= " 		C9_CARGA, "	
	cQuery	+= " 		B1_PESBRU, "
	cQuery	+= " 		C6_QTDVEN, "
	cQuery	+= " 		C6_UNSVEN, "
	cQuery	+= " 		B1_XMARCA "// Max Nascimento - Chamado 144330
	cQuery	+= " FROM " + RetSqlName("SC6") + " SC6 " 
	cQuery	+= " INNER JOIN " + RetSqlName("SC5") + " SC5 ON C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM AND SC5.D_E_L_E_T_ = ' ' " 
	cQuery	+= " INNER JOIN " + RetSqlName("SB1") + " SB1 ON B1_COD = C6_PRODUTO AND SB1.D_E_L_E_T_ = ' ' " 
	cQuery	+= " INNER JOIN " + RetSqlName("SC9") + " SC9 ON (C9_FILIAL=C6_FILIAL AND C9_PEDIDO=C6_NUM AND C9_ITEM=C6_ITEM AND C9_PRODUTO=C6_PRODUTO AND C9_CARGA <> ' ' AND SC9.D_E_L_E_T_ = ' ') "
	
	cQuery 	+= " INNER JOIN " + RetSQLName("DAI") + " DAI ON( DAI.D_E_L_E_T_ = ' '	AND C5_FILIAL = DAI_FILIAL	AND C5_NUM = DAI_PEDIDO ) "
	cQuery 	+= " INNER JOIN " + RetSQLName("DAK") + " DAK ON( DAK.D_E_L_E_T_ = ' '	AND DAI_FILIAL = DAK_FILIAL AND DAI_COD = DAK_COD AND DAI_SEQCAR = DAK_SEQCAR ) "

	cQuery	+= " WHERE C6_FILIAL = '" + xFilial("SC6") + "' " 
	cQuery	+= " 	AND   C6_LOCAL = '" + MV_PAR01 + "' " 
	cQuery	+= " 	AND   DAK_DATA BETWEEN '" + DTOS(MV_PAR02) + "' AND '" + DTOS(MV_PAR03) + "' " 
	cQuery	+= " 	AND   SC6.D_E_L_E_T_ = ' ' "
	cQuery	+= " 	AND   DAK_COD BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' " 
	
	If !(cFilAnt $ cFilPes)// Max Nascimento - Filiais peso variavel
		If MV_PAR07 = 1 // Juliano - Peso variavel
			cQuery	+= " 	AND   SB1.B1_XPESVAR = 'S' "  
		EndIf   
	Endif

	cQuery	:= ChangeQuery(cQuery)
	cAlias	:= MPSysOpenQuery(cQuery)

	//Monta o array com o conteudo para geraração do arquivo .csv
	While !(cAlias)->(Eof())
		
		cTpFrete	:= ' '
		If (cAlias)->TPFRETE == 'C'
			cTpFrete	:= '1'
		EndIf	
		If (cAlias)->TPFRETE == "F"                                                                                                              
			cTpFrete	:= '2'
		EndIf	

		IF (cAlias)->C5_TIPO $ "B/D"
			SA2->(DbSetOrder(1))
			SA2->(DbSeek(FWxFilial("SA2")+(cAlias)->CLIENT+(cAlias)->LOJA ))
			cNome    := SA2->A2_NOME
			cCidade  := SA2->A2_MUN
			cBairro  := SA2->A2_BAIRRO
			cEstado  := SA2->A2_EST
			cCgcDes	 := SA2->A2_CGC
		Else
			SA1->(DbSetOrder(1))
			SA1->(DbSeek(FWxFilial("SA1")+(cAlias)->CLIENT+(cAlias)->LOJA ))
			cNome    := SA1->A1_NOME
			cCidade  := SA1->A1_MUN
			cBairro  := SA1->A1_BAIRRO
			cEstado  := SA1->A1_EST
			cCgcDes	 := SA1->A1_CGC				                
		Endif
		
		dDtCar := CTOD("//")
		DAI->(DbSetOrder(4)) //DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
		If DAI->(DbSeek(FWxFilial("DAI") + (cAlias)->NUM_PEDIDO + (cAlias)->C9_CARGA ))
			cItCarga	:= DAI->DAI_COD
			cSeqCar		:= DAI->DAI_SEQCAR
			cSeq		:= DAI->DAI_SEQUEN
			DAK->(DbSetOrder(1)) //DAK_FILIAL+DAK_COD+DAK_SEQCAR
			If DAK->(DbSeek(FWxFilial("DAK")+ DAI->DAI_COD + DAI->DAI_SEQCAR))
				cCodVei	:= DAK->DAK_CAMINH
				dDtCar	:= DAK->(DAK_DATA)
			EndIf	
		Else
			cItCarga	:= ""
			cSeqCar		:= ""
			cSeq		:= ""
			cCodVei		:= ""
		EndIf

		If Empty(cCodVei)
			cCodVei := "SEMPLACA"
		Else
			lRet := .T.
		EndIf

		AaDd(aRows,{;
			(cAlias)->FIL_CLIENTE,;     // 01
			(cAlias)->NF,;				// 02
			(cAlias)->SERIE,;			// 03
			cNome,;             		// 04
			cCidade,;          			// 05
			cEstado,;       			// 06
			(cAlias)->SKU,;			    // 07
			(cAlias)->DESCRICAO,;		// 08
			(cAlias)->QUANT,;			// 09
			cBairro,;          			// 10
			(cAlias)->DATA_PRD,;		// 11
			(cAlias)->FAIXA,;			// 12
			(cAlias)->ORDENT,;			// 13
			(cAlias)->LOTE,;			// 14
			(cAlias)->PRODUTO,;		    // 15
			(cAlias)->V_UNITARIO,;		// 16
			(cAlias)->V_TOTAL,;		    // 17
			(cAlias)->CLIENT,;			// 18
			(cAlias)->LOJA,;			// 19
			(cAlias)->NUM_PEDIDO,;		// 20
			(cAlias)->DATA_PEDIDO,;	    // 21
			(cAlias)->PESO_LIQ_PEDIDO,; // 22
			(cAlias)->PESO_BRUTO,;		// 23
			(cAlias)->NUM_LOTE,;		// 24
			(cAlias)->DATA_ENT,;		// 25
			(cAlias)->PESO,;			// 26
			ConvUm((cAlias)->PRODUTO,(cAlias)->QUANT,0,2) ,; // 27
			(cAlias)->C5_VEND1,;		// 28
			(cAlias)->C5_XFORMA,;		// 29
			(cAlias)->C6_ENTREG,;		// 30
			(cAlias)->C6_SUGENTR,;		// 31
			cTpFrete,;					// 32
			cItCarga,;					// 33
			cSeqCar,;					// 34
			cSeq,;						// 35
			cCodVei,;					// 36
			cCgcDes,;					// 37
			(cAlias)->C9_CARGA,;	    // 38	
			dDtCar,;					// 39
			(cAlias)->B1_PESBRU,;		// 40
			(cAlias)->ITEM,;		    // 41
			(cAlias)->C6_QTDVEN,;		// 42
			(cAlias)->C6_UNSVEN,;		// 43
			(cAlias)->B1_XMARCA;		// 44 Max Nascimento - Chamado 144330
			})					
		
		//Monta o array para impressão do relatório conforme mv_par01
		AaDd(aRel,{(cAlias)->NUM_PEDIDO,(cAlias)->ITEM,(cAlias)->QUANT,(cAlias)->QUANT*(cAlias)->PESO,(cAlias)->NF,(cAlias)->C6_SERIE})	

		(cAlias)->(DbSkip())
	EndDo
	
	(cAlias)->(DBCloseArea())

	IF Len(aRows) = 0
		MsgAlert("Não foram encontrados movimentos para o período informado nos parâmetros!" )
		Return 
	Endif

	//ArFrio
    If cLayout == "1"  // 1=AirFrio;2=ComFrio;3=UniFrango;4=ViFrio;5=EngeCompany

		cArqCsv	:= cLocArq + cNomeArq + ".TXT"
		nHld	:= FCreate(cArqCsv)

		cFilArFr := SUPERGETMV( "FS_C040151", .F., "00000", cFilAnt ) // Filial Ar Frio -> parâmetro exclusivo por filial

		If nHld = -1
			MsgAlert("Erro ao criar arquivo - ferror " + Str(Ferror()))
			Return 
		Endif

		aRows := aSort(aRows,,,{|x,y| x[36]+x[15] < y[36]+y[15] }) // DAK_CAMINH + C6_PRODUTO
		
		For nX := 1 To Len(aRows)

			if !empty(cFilMarc)//Max Nascimento - Chamado 144330
				If (aRows[nX][44]=='99A')
					cFilArFr := SUPERGETMV( "FS_C040152", .F., "00000", cFilAnt )
				else
					cFilArFr := SUPERGETMV( "FS_C040151", .F., "00000", cFilAnt ) // Filial Ar Frio -> parâmetro exclusivo por filial
				EndIf
			Endif

			cRow := Substr(dtos(dDatabase),7,2)+Substr(dtos(dDatabase),5,2)+Substr(dtos(dDatabase),1,4)+CHR(09) //001 - 008 = 08 - DATA 
			cRow += cFilArFr+CHR(09)     												                        //009 - 012 = 05 - FILIAL
			cRow += PadL(Substr(Alltrim(aRows[nX][20])    ,1,6),6,'0') //pedido                                //013 - 025 = 13 - CARGA
			cRow += PadL(Substr(Alltrim(aRows[nX][38])    ,1,6),7,'0')+CHR(09)                                //013 - 025 = 13 - CARGA
			cRow += "1"+CHR(09)                                                                                 //026 - 026 = 01 - FIXO 1
			cRow += PadR(Substr(Alltrim(aRows[nX][04])    ,1,30),30,' ')+CHR(09)                                //027 - 056 = 30 - CLIENTE
			cRow += PadR(Substr(Alltrim(aRows[nX][05])    ,1,20),20,' ')+CHR(09)                                //057 - 076 = 20 - CIDADE
			cRow += PadR(Substr(Alltrim(aRows[nX][06])    ,1,02),02,' ')+CHR(09)                                //077 - 078 = 02 - UF
			cRow += PadR(Substr(Alltrim(aRows[nX][07])    ,1,06),06,' ')+CHR(09)                                //079 - 084 = 06 - SKU
			cRow += PadR(Substr(Alltrim(aRows[nX][08])    ,1,20),20,' ')+CHR(09)                                //085 - 104 = 20 - DESCRICAO
			cRow += PadL(StrTran(Alltrim(Str(aRows[nX][27])),'.','')  ,05,'0')+CHR(09)                          //105 - 109 = 05 - QUANT
			cRow += PadR(Substr(Alltrim(aRows[nX][10])    ,1,15),15,' ')+CHR(09)                                //110 - 124 = 15 - BAIRRO 
			cRow += PadR(Substr(Alltrim(aRows[nX][11])    ,1,08),08,' ')+CHR(09)                                //125 - 132 = 08 - DT_PRD
			// Alterado por solicitação do Usuario - Chamado 12777730	
			//cRow += PadL(StrTran(Alltrim(Str(aRows[nX][12])),'.','')+".00",06,' ')+CHR(09)                    //133 - 137 = 05 - FAIXA
			cRow += PadL(Alltrim(TRANSFORM(aRows[nX][12],"@E 9,999.99"))	  ,06,' ') +CHR(09)      		    //133 - 137 = 05 - FAIXA
			cRow += PadR(Substr(Alltrim(aRows[nX][36])    ,1,13),13,' ')+CHR(09)                                //138 - 150 = 13 - ORDENT
			cRow += PadR(Substr(Alltrim(aRows[nX][14])    ,1,20),20,' ')                                        //151 - 170 = 20 - LOTE

			FWrite(nHld, cRow + CRLF)

		Next nX

		FClose(nHld)
		
		If MsgNoYes( "Deseja imprimir o relatório de separação ?", cRelTit )
			U_F0401502(aRel)
		EndIf	

    ElseIf cLayout == "2" // 1=AirFrio;2=ComFrio;3=UniFrango;4=ViFrio;5=EngeCompany
    
    	cNomeArq 	:= ""
    	aRows		:= aSort(aRows,,,{|x,y| x[36]+x[15] < y[36]+y[15] }) // DAK_CAMINH + C6_PRODUTO
    	cPlaca		:= ""
		
		For nX := 1 To Len(aRows)
			
			If cPlaca <> aRows[nX][36]
				
				If !Empty(cNomeArq)
					FClose(nHld)
				EndIf
				
				cPlaca 		:= aRows[nX][36]
				cNomeArq	:= DToS(DDatabase)+"_"+cPlaca 
				cArqCsv		:= cLocArq + cNomeArq + ".TXT"
				nHld		:= FCreate(cArqCsv)

				If nHld = -1
					MsgAlert("Erro ao criar arquivo - ferror " + Str(Ferror()))
					Return nil 
				Endif				
			EndIf
			
			//Recalcula o peso do produto
			nPeso 		:= aRows[nX][9] 							// C9_QTDLIB
			nPesoProd 	:= OsPesoProd(aRows[nX][15],aRows[nX][01]) 	//Identifica o peso do Produto                        
			IF nPesoProd > 0
				nPeso := aRows[nX][9] * nPesoProd
			Endif

			cRow := PadL(Substr(aRows[nX][33]         ,1,10),10,'0')               //001-010 = 10 - Carga
			cRow += PadR(Substr(aRows[nX][36]         ,1,08),08,' ')               //011-030 = 20 - Placa
			cRow += Space(12)
			cRow += PadL(Substr(aRows[nX][34]         ,1,04),04,'0')               //031-044 = 14 - Sequencia Linha de Entrega
			cRow += PadL(Substr(aRows[nX][35]         ,1,10),10,'0')       	       //045-034 = 04 - Numero da entrega
			cRow += Space(55)                                             	       //108-145 = 38 - CNPJ ponto de Engrega
			cRow += PadL(Alltrim(aRows[nX][07]),08,'0')              			   //100-107 = 08 - Produto
			cRow += PadR(Substr(aRows[nX][08]         ,1,42),42,' ')      	       //108-145 = 38 - Descrição
			cRow += PadL(StrTran(Alltrim(Str(nPeso*10000)),'.',''),15,' ') 		   //150-164 = 15 - Peso
			cRow += Space(19)                                             	       //108-145 = 38 - Complem campo
			cRow += PadL(StrTran(Alltrim(Str(aRows[nX][27]*10000)),'.',''),15,' ') //184-198 = 15 - Qtde_Solic -> em caixas (seg. um)
			cRow += "00"                                                           //199-200 = 02 - Decorrido

			FWrite(nHld, cRow + CRLF)

		Next nX			
		
		FClose(nHld)
		
		If lRet
			aRows		:= aSort(aRows,,,{|x,y| x[15] < y[15] }) // C6_PRODUTO
			cNomeArq	:= DToS(DDatabase) + STRTRAN(TIME(),":","") 
			cArqCsv		:= cLocArq + cNomeArq + ".CSV"
			nHld		:= FCreate(cArqCsv)

			If nHld = -1
				MsgAlert("Erro ao criar arquivo - ferror " + Str(Ferror()))
				Return 
			Endif
			cRow 		:= ""
			cProd		:= ""
			nQtd		:= 0
			nPesLiq 	:= 0
			nPesBru 	:= 0
			nPrcUni 	:= 0
			nPrcTot 	:= 0
			
			For nX := 1 To Len(aRows)
				
				If cProd <> aRows[nX][15]

					If !Empty(cRow)
						cRow += Str(nQtd)+";"  //Quantidade
						cRow += Str(nPesLiq)+";" //Peso_Liq
						cRow += Str(nPesBru)+";" //Peso_Bruto
						cRow += Str(nPrcUni)+";" //Prc_unitario
						cRow += Str(nPrcTot)     //Prc_total						
						FWrite(nHld, cRow + CRLF)
					EndIf
					
					cRow := aRows[nX][15]+";"      //SKU  
					cRow += aRows[nX][8]+";"       //Descrição
					
					cProd 		:= aRows[nX][15]
					nQtd 		:= aRows[nX][9]  //Quantidade
					nPesLiq 	:= aRows[nX][22] //Peso_Liq
					nPesBru 	:= aRows[nX][23] //Peso_Bruto
					nPrcUni 	:= aRows[nX][16] //Prc_unitario
					nPrcTot 	:= aRows[nX][17] //Prc_total					
				Else
					nQtd += aRows[nX][9]  //Quantidade
					nPesLiq += aRows[nX][22] //Peso_Liq
					nPesBru += aRows[nX][23] //Peso_Bruto
					nPrcUni += aRows[nX][16] //Prc_unitario
					nPrcTot += aRows[nX][17] //Prc_total				
				EndIf
				
			Next nX
			
			cRow += Str(nQtd)+";"    //Quantidade
			cRow += Str(nPesLiq)+";" //Peso_Liq
			cRow += Str(nPesBru)+";" //Peso_Bruto
			cRow += Str(nPrcUni)+";" //Prc_unitario
			cRow += Str(nPrcTot)     //Prc_total						
			FWrite(nHld, cRow + CRLF)			
			FClose(nHld)
			
		EndIf	

		If MsgNoYes( "Deseja imprimir o relatório de separação ?", cRelTit )
			U_F0401502(aRel)
		Else	
			Return				
		EndIf	

	ElseIf cLayout == "3" // 1=AirFrio;2=ComFrio;3=UniFrango;4=ViFrio;5=EngeCompany

		If MV_PAR07 = 2 //1-sim e 2-nao   - Juliano chamado 129826 Peso variavel
			cNomeArq	:= DToS(DDatabase) + STRTRAN(TIME(),":","") 
			cArqCsv		:= cLocArq + cNomeArq + ".TXT"
			nHld		:= FCreate(cArqCsv)

			If nHld = -1
				MsgAlert("Erro ao criar arquivo - ferror " + Str(Ferror()))
				Return 
			Endif

			cRow := "1"                                                                                 //001 - 001 = 01 - IDENTIFICADOR
			cRow += PadR(Substr(Alltrim(cCgcEmit),1,14),14,' ')                                         //002 - 015 = 14 - CNPJ_FILIAL EMIT
			cRow += PadR(Substr(Alltrim(cNomeEmit)   ,1,50),50,' ')                                     //016 - 065 = 50 - CLI_NOME FILIAL EMIT
			cRow += Substr(dtos(dDatabase),7,2)+Substr(dtos(dDatabase),5,2)+Substr(dtos(dDatabase),3,2) //066 - 072 = 06 - DATA_ARQ
			
			FWrite(nHld, cRow + CRLF)

			cRow		:= ""
			cCarga		:= ""
			cCargaAnt	:= ""

			aRows	:= aSort(aRows,,,{|x,y| x[38]+x[15]+x[36] < y[38]+y[15]+y[36]}) // C9_CARGA + C6_PRODUTO + DAK_CAMINH

			For nX := 1 To Len(aRows)
				cCarga := aRows[nX][38]

				If nX == 1 .or. cCargaAnt <> cCarga
					// totaliza por carga
					nQuant 	:= 0
					nValor 	:= 0
					nitens	:= 0
					nTtPeso	:= 0
					For nT := nX To Len(aRows)
						If aRows[nT][38] <> cCarga
							Exit
						Endif

						nQuant 	+= aRows[nT][9]
						nValor 	+= NoRound( aRows[nT][16] * aRows[nT][9], 2) // C6_PRCVEN * C9_QTDLIB
						nitens	+= 1

						//Recalcula o peso do produto
						nPeso 		:= aRows[nT][9] * aRows[nT][26]	// C9_QTDLIB * B1_PESO
						nPesoBru	:= aRows[nT][9] * aRows[nT][40]	// C9_QTDLIB * B1_PESBRU
						nTtPeso 	+= nPeso
						nTtPesoB 	+= nPesoBru
					Next nT		

					cRow := "2"                                                               				//001 - 001 = 01 - IDENTIFICADOR
					cRow += Space(10)                                                         				//002 - 011 = 10 - COD_DESTINATARIO
					cRow += PadR(Substr(Alltrim(cClient)     ,1,50),50,' ')  								//012 - 061 = 50 - RAZ_SOC_DESTINATARIO
					cRow += PadR(Substr(Alltrim(cEnd)        ,1,50),50,' ')                             	//062 - 111 = 50 - ENDE_ENTREGA
					cRow += PadR(Substr(Alltrim(cBairro)     ,1,20),20,' ')                             	//112 - 131 = 20 - BAIRRO_ENTREGA
					cRow += PadR(Substr(Alltrim(cCep)        ,1,09),09,' ')                             	//132 - 140 = 09 - CEP_ENTREGA
					cRow += PadR(Substr(Alltrim(cMum)        ,1,25),25,' ')                             	//141 - 165 = 25 - CIDADE_ENTREGA
					cRow += PadR(Substr(Alltrim(cUf)         ,1,02),02,' ')                             	//166 - 167 = 02 - ESTADO_ENTREGA
					cRow += PadR(Substr(Alltrim(aRows[nX][38]),1,10),10,' ')                             	//168 - 177 = 10 - CARGA
					cRow +=  StrZero(Day(  aRows[nX][39]),2) +;
							StrZero(Month(aRows[nX][39]),2) +;
							Substr(alltrim(Str(Year(aRows[nX][39]))),3,2) 									//178 - 183 = 06 - DATA_CARGA DDMMAA
					cRow += PadL(Alltrim(Str(nitens))      ,04,'0')  										//184 - 187 = 04 - QTDE_ITENS
					cRow += Padl(strTran(Alltrim(Str(nValor*100)),'.',''),13,'0')	 						//188 - 200 = 13 - VLR_TOT_PEDIDO
					cRow += PadL(Alltrim(Str(nTtPeso*1000)),10,'0') 										//201 - 210 = 10 - PESO_LIQ_PEDIDO
					cRow += PadR(Substr(Alltrim(aRows[nX][2]) ,1,10),10,' ')  								//211 - 220 = 10 - NUM_NF
					cRow += PadR(Substr(Alltrim(aRows[nX][3]) ,1,10),10,' ')  								//221 - 230 = 10 - SERIE
					cRow += PadR(Substr(Alltrim(aRows[nX][38]),1,10),10,' ')                             	//231 - 240 = 10 - NUM_CARGA
					cRow += PadL(Alltrim(Str(nTtPesoB*1000)),10,'0')										//241 - 250 = 10 - PESO_BRT_PEDIDO
					cRow += PadR(Substr(Alltrim(cCgcEmit)          ,1,14),14,' ')                     		//251 - 265 = 14 - CNPJ_CPF_DEST

					FWrite(nHld, cRow + CRLF)
				Endif
		
				//Layout 3
				cDes3Prod 	:= aRows[nX][08] // DESCR_PRODUTO
				nVlr3Prod	:= aRows[nX][16] // VLR_UNITARIO
				cPla3Prod	:= aRows[nX][36] // PLACA_VEICULO
				cPro3Prod	:= aRows[nX][15] // COD_PRODUTO
				nPes3Uni	:= aRows[nx][26] // PESO PRODUTO

				nQtd3Prod	:= 0
				nVol3Prod	:= 0

				// aglutina por produto + placa
				cProdPlac	:= aRows[nX][15] + aRows[nX][36] 
				nUIni 		:= nX
				For nU := nUIni To Len(aRows)
					If cProdPlac == aRows[nU][15] + aRows[nU][36] 
						nQtd3Prod	+= aRows[nU][09] // QTDE_PRODUTO
						nVol3Prod	+= aRows[nU][27] // QTDE_VOLUMES
					Else
						Exit
					Endif
					nX := nU
				Next nU 

				nPes3Prod	:= nQtd3Prod * nPes3Uni

				cRow := "3"                                                       					//001 - 001 = 01 - IDENTIFICADOR
				cRow += Space(10)                                                 					//002 - 011 = 10 - COD_PRODUTO_ANT
				cRow += PadR(Substr(Alltrim(cDes3Prod)      ,1,50),50,' ')    						//012 - 061 = 50 - DESCR_PRODUTO
				cRow += PadL(StrTran(Alltrim(Str(nQtd3Prod)),'.',''),05,'0')  						//062 - 065 = 04 - QTDE_PRODUTO
				cRow += PadL(StrTran(Alltrim(Str(nVlr3Prod*100000)),'.',''),13,'0')  				//066 - 078 = 13 - VLR_UNITARIO
				cRow += PadL(StrTran(Alltrim(Str(nPes3Prod*1000)),'.',''),10,'0')  					//079 - 088 = 10 - PESO_LIQ_ITEM
				cRow += Space(10)    																//089 - 099 = 11 - NUM_PEDIDO CLIENTE
				cRow += PadR(Substr(Alltrim(cPla3Prod)      ,1,11),11,' ')							//100 - 110 = 11 - PLACA_VEICULO
				cRow += PadL(Alltrim(cPro3Prod),20,"0")    					  						//111 - 130 = 20 - COD_PRODUTO - preencher com zeros a esquerda conforme GMUD037
				cRow += PadL(StrTran(Alltrim(Str(nVol3Prod)),'.',''),10,'0')  						//131 - 140 = 10 - QTDE_VOLUMES
				cRow += Space(01)																	//141 - 151 = 10 - NUM_LOT_FABR

				FWrite(nHld, cRow + CRLF)

				cCargaAnt 	:= aRows[nX][38]
			Next nX

			FClose(nHld)
			
			If MsgNoYes( "Deseja imprimir o relatório de separação ?", cRelTit )
				U_F0401502(aRel)
			EndIf	
		else  //Gera o arquivo do peso variavel
			aRows	    := aSort(aRows,,,{|x,y| x[38]+x[20]+x[41] < y[38]+y[20]+y[41]}) // C9_CARGA + NUM_PEDIDO + C6_ITEM
			cCargaAnt	:= ""
			cCarga      := aRows[1][38]
			cNomeArq	:= DToS(DDatabase) + STRTRAN(TIME(),":","") + cCarga 
			cArqCsv		:= cLocArq + cNomeArq + ".TXT"
			nHld		:= FCreate(cArqCsv)

			If nHld = -1
				MsgAlert("Erro ao criar arquivo - ferror " + Str(Ferror()))
				Return 
			Endif

			//Inlcui o cabeçalho
			cCab := ""
			cCab += PadR(Substr("CARGA",1,10),10,' ') + ";"   //C9_CARGA
			cCab += PadR(Substr("PEDIDO",1,15),15,' ') + ";"   //NUM_PEDIDO      
			cCab += PadR(Substr("CODCLI",1,10),10,' ') + ";"	 //C6_CLI
			cCab += PadR(Substr("LJ",1,02),02,' ') + ";" 	 //C6_LOJA                          
			cCab += PadR(Substr("NOME",1,30),30,' ') + ";"   //A1_NOME
			cCab += PadR(Substr("CIDADE",1,20),20,' ') + ";"   //A1_MUN                       
			cCab += PadR(Substr("PLACA",1,13),13,' ') + ";"   //DAK_CAMINH    
			cCab += PadR(Substr("COD PROD",1,15),15,' ') + ";" 	 //C6_PRODUTO
			cCab += PadR(Substr("IT",1,02),02,' ') + ";"   //C6_ITEM	                          
			cCab += PadR(Substr("DESCRICAO PROD",1,40),40,' ') + ";"   //C6_DESCRI                             
			cCab += PadR(Substr("CX",1,15),15,' ') + ";"	 //C6_UNSVEN                         
			cCab += PadR(Substr("PESLIQ",1,15),15,' ')        //C6_QTDVEN                         
			FWrite(nHld, cCab + CRLF)

			For nX := 1 To Len(aRows)
				cCarga := aRows[nX][38]
				cRow := ""
				cRow += PadR(Substr(Alltrim(aRows[nX][38]),1,10),10,' ') + ";"   //C9_CARGA
				cRow += PadR(Substr(Alltrim(aRows[nX][20]),1,15),15,' ') + ";"   //NUM_PEDIDO      
				cRow += PadR(Substr(Alltrim(aRows[nX][18]),1,10),10,' ') + ";"	 //C6_CLI
				cRow += PadR(Substr(Alltrim(aRows[nX][19]),1,02),02,' ') + ";" 	 //C6_LOJA                          
				cRow += PadR(Substr(Alltrim(aRows[nX][04]),1,30),30,' ') + ";"   //A1_NOME
				cRow += PadR(Substr(Alltrim(aRows[nX][05]),1,20),20,' ') + ";"   //A1_MUN                       
				cRow += PadR(Substr(Alltrim(aRows[nX][36]),1,13),13,' ') + ";"   //DAK_CAMINH    
					If !(cFilAnt $ cFilPes)// Max Nascimento - Cod produto do canção
						cRow += PadR(Substr(Alltrim(aRows[nX][15]),1,15),15,' ') + ";" 	 //C6_PRODUTO
					Else
						cRow += PadR(Substr(Alltrim(aRows[nX][7]),1,15),15,' ') + ";" 	 //B1_XCODCAN
					Endif
				cRow += PadR(Substr(Alltrim(aRows[nX][41]),1,02),02,' ') + ";"   //C6_ITEM	                          
				cRow += PadR(Substr(Alltrim(aRows[nX][08]),1,40),40,' ') + ";"   //C6_DESCRI                             
				cRow += PadR(Substr(Alltrim(STR(aRows[nX][43])),1,15),15,' ') + ";"	 //C6_UNSVEN                         
				cRow += PadR(Substr(Alltrim(STR(aRows[nX][42])),1,15),15,' ')        //C6_QTDVEN                         

				If nX == 1 .or. cCargaAnt == cCarga
					FWrite(nHld, cRow + CRLF)
				Else
					FClose(nHld)
					cNomeArq	:= DToS(DDatabase) + STRTRAN(TIME(),":","") + cCarga
					cArqCsv		:= cLocArq + cNomeArq + ".TXT"
					nHld		:= FCreate(cArqCsv)
					FWrite(nHld, cCab + CRLF) //Cabeçalho
					FWrite(nHld, cRow + CRLF)
				EndIf

				cCargaAnt 	:= aRows[nX][38]

			Next nX

			FClose(nHld)
		EndIf
	ElseIf cLayout == "4" // 1=AirFrio;2=ComFrio;3=UniFrango;4=ViFrio;5=EngeCompany

		cNomeArq	:= DToS(DDatabase) + STRTRAN(TIME(),":","") 
		cArqCsv		:= cLocArq + cNomeArq + ".TXT"
		nHld		:= FCreate(cArqCsv)

		If nHld = -1
			MsgAlert("Erro ao criar arquivo - ferror " + Str(Ferror()))
			Return 
		Endif

		SC5->(DbSetOrder(1))

		aRows := aSort(aRows,,,{|x,y| x[36]+x[15] < y[36]+y[15] }) // DAK_CAMINH + C6_PRODUTO

		For nX := 1 To Len(aRows)

			SA1->(DbSetOrder(1))
			If SA1->(DbSeek(FWxFilial()+ aRows[nX][18] + aRows[nX][19]))
				cClient	:= SA1->A1_NOME
				cEnd	:= SA1->A1_END
				cBairro	:= SA1->A1_BAIRRO
				cCep	:= SA1->A1_CEP 
				cMum	:= SA1->A1_MUN
				cUf		:= SA1->A1_EST
				cCgcDes	:= SA1->A1_CGC
				cIe		:= SA1->A1_INSCR
				cCompl	:= SA1->A1_COMPLEM
				cCodMun	:= SA1->A1_COD_MUN
				cFone	:= SA1->A1_TEL
			EndIf	

			nPeso	:= 	aRows[nX][9]*aRows[nX][26]	

			DAI->(DbSetOrder(4)) //DAI_FILIAL, DAI_PEDIDO, DAI_COD, DAI_SEQCAR
			If DAI->(DbSeek(FWxFilial()+ aRows[nX][20] ))
				cCodCarg	:= DAI->DAI_COD
				cNota		:= DAI->DAI_NFISCAL 
				cSerie		:= DAI->DAI_SERIE 
			EndIf

			cC5_X_V_RM := Posicione("SC5",1,xFilial("SC5")+aRows[nX][20] ,"C5_X_V_RM")
			
			cRow := PadR(Substr(Alltrim(aRows[nX][20]),1,15),15,' ')         //001 - 015 = 15 - Num_Pedido_Cliente
			cRow += PadR(Substr(Alltrim(aRows[nX][18]),1,04),04,' ')         //016 - 019 = 04 - Cod_Cliente
			cRow += PadR(Substr(Alltrim(aRows[nX][21]),1,08),08,' ')         //020 - 027 = 08 - Data_Ped
			cRow += PadR(Substr(Alltrim(aRows[nX][25]),1,08),08,' ')         //028 - 035 = 08 - Data_Entr_Prev
			cRow += PadR(Substr(Alltrim(cClient)      ,1,60),60,' ')         //036 - 095 = 60 - Razao
			cRow += PadR(Substr(Alltrim(cCgcDes)      ,1,50),50,' ')         //096 - 145 = 50 - CNPJ
			cRow += PadR(Substr(Alltrim(cIe)          ,1,15),15,' ')         //146 - 160 = 15 - Inscr_Est
			cRow += PadR(Substr(Alltrim(cEnd)         ,1,60),60,' ')         //161 - 220 = 60 - End
			cRow += Space(60)                                                //221 - 280 = 60 - End_Num
			cRow += PadR(Substr(Alltrim(cCompl)       ,1,60),60,' ')         //281 - 340 = 60 - Complemento
			cRow += PadR(Substr(Alltrim(cBairro)      ,1,40),40,' ')         //341 - 380 = 40 - Bairro
			cRow += PadR(Substr(Alltrim(cUf)          ,1,02),02,' ')         //381 - 382 = 02 - UF
			cRow += PadR(Substr(Alltrim(cCep)         ,1,08),08,' ')         //383 - 390 = 08 - CEP
			cRow += PadR(Substr(Alltrim(cCodMun)      ,1,07),07,' ')         //391 - 397 = 07 - Cod_Munic_Cli
			cRow += PadR(Substr(Alltrim(cFone)        ,1,25),25,' ')         //398 - 422 = 25 - Fone_Fax
			cRow += PadR(Substr(Alltrim(aRows[nX][07]),1,15),15,' ')         //423 - 437 = 15 - Cod_Prod_Cliente
			cRow += PadR(Substr(Alltrim(aRows[nX][08]),1,100),100,' ')       //438 - 537 = 100- Nome_Prod
			cRow += Space(08)                                                //538 - 545 = 08 - NCM
			cRow += PadR(Substr(Alltrim(aRows[nX][24]),1,25),25,' ')         //546 - 570 = 25 - Lote
			cRow += Space(04)                                                //571 - 574 = 04 - Num_Emb
			cRow += PadL(StrTran(Alltrim(Str(nPeso))        ,'.',''),08,'0') //575 - 580 = 08 - Peso_Real
			cRow += PadL(StrTran(Alltrim(Str(aRows[nX][16])),'.',''),04,'0') //581 - 586 = 04 - Valor_Unit_R
			cRow += "0"                                                      //587 - 587 = 01 - Decimal
			cRow += PadL(StrTran(Alltrim(Str(aRows[nX][17])),'.',''),03,'0') //588 - 590 = 03 - Valor_Unit_
			cRow += PadR(Substr(Alltrim(cC5_X_V_RM)   ,1,100),100,' ')       //591 - 690 = 100- Obs_Ped
			cRow += PadR(Substr(Alltrim(cCodCarg)     ,1,10),10,' ')         //691 - 700 = 10 - Num_Carga
			cRow += PadR(Substr(Alltrim(cNota)        ,1,09),09,' ')         //701 - 710 = 09 - Nota_Fiscal
			cRow += PadR(Substr(Alltrim(cSerie)       ,1,03),03,' ')         //711 - 713 = 03 - Serie
                                                                                
			FWrite(nHld, cRow + CRLF)                                           

		Next nX

		FClose(nHld)
		
		If MsgNoYes( "Deseja imprimir o relatório de separação ?", cRelTit )
			U_F0401502(aRel)
		EndIf
			
	ElseIf cLayout == "5" // 1=AirFrio;2=ComFrio;3=UniFrango;4=ViFrio;5=EngeCompany

		cNomeArq	:= DToS(DDatabase) + STRTRAN(TIME(),":","") 
		cArqCsv		:= cLocArq + cNomeArq + ".CSV"
		nHld		:= FCreate(cArqCsv)

		If nHld = -1
			MsgAlert("Erro ao criar arquivo - ferror " + Str(Ferror()))
			Return 
		Endif

		//Layout 1
		aLayout := {"COD_PEDIDO","TIPO_REGISTRO","COD_CLIENTE","COD_REPRESENTANTE","TIPO_FRETE","DATA_CARREGAMENTO","DATA_ENTREGA","FORM_PAGAMENTO","COD_PREPOSTO","CNPJ_CLIENTE"}
		
		For nX := 1 To Len(aRows)
	
			If aRows[nX][20] <> cPed

				cPed	:= aRows[nX][20]
				SA1->(DbSetOrder(1))
				If SA1->(DbSeek(FWxFilial()+ aRows[nX][18] + aRows[nX][19]))
					cCgcDes	:= SA1->A1_CGC
				EndIf	

				cRow := aRows[nX][20] + ";"
				cRow += "1" + ";"
				cRow += " " + ";"
				cRow += "4166" + ";"
				cRow += aRows[nX][32] + ";"
				cRow += Dtoc(Stod(aRows[nX][31])) + ";" 
				cRow += Dtoc(Stod(aRows[nX][30])) + ";"
				cRow += aRows[nX][29] + ";"
				cRow += IIF(Empty(aRows[nX][28]),aRows[nX][28],PadL(aRows[nX][28],6,'0') ) + ";"
				cRow += cCgcDes 

				FWrite(nHld, cRow + CRLF)

			EndIf	

			cRow	:= ""
			aLayout	:= {}

		Next nX


		For nX := 1 To Len(aRows)

			//Layout 2
			cRow := aRows[nX][20] + ";"      //COD_PEDIDO
			cRow += Str(aRows[nX][9]) + ";"  //TIPO_REGISTRO
			cRow += aRows[nX][7] + ";"       //COD_PRODUTO
			cRow += Str(aRows[nX][16]) + ";" //VALOR_KG
			cRow += Str(aRows[nX][27]) + ";" //EMBALAGEM
			cRow += " " + ";"
			cRow += " " + ";"
			cRow += " "

			FWrite(nHld, cRow + CRLF)
	
		Next nX

		cRow	:= ""
		aLayout := {}
		cPed	:= ""
		//Layout 3
		aLayout := {"COD_PEDIDO","TIPO_REGISTRO","TIPO_PARCELA","DIAS","","",""}

		cRow += CRLF
		AEval(aLayout,{|h| cRow += h + ";" })
		cRow += CRLF


		For nX := 1 To Len(aRows)

			If aRows[nX][20] <> cPed
				cPed	:= aRows[nX][20]
				cRow += aRows[nX][20] + ";"
				cRow += " " + ";"
				cRow += " " + ";"
				cRow += " " + ";"
				cRow += " " + ";"
				cRow += " " + ";"
				cRow += " " 

				FWrite(nHld, cRow + CRLF)

			EndIf	

			cRow	:= ""

		Next nX	
		
		FClose(nHld)		
		
		If MsgNoYes( "Deseja imprimir o relatório de separação ?", cRelTit )
			U_F0401502(aRel)
		EndIf	

    EndIf

	RestArea(aAreaNNR)
	RestArea(aAreaSB1)	    
	RestArea(aAreaDAI)	    
	RestArea(aAreaDAN)	    
	RestArea(aAreaSA1)	    
	RestArea(aAreaSC5)	    

Return 


/*/{Protheus.doc} fCriaSX1
Cria as perguntas no arquido de dados SX1, caso não existam.
@author 	Ronaldo Dantas
@since 		11/10/2019
@version 	12.1.23
@type 		Function
@param 		cPerg, characters, código da pergunta a ser gravado no SX1
/*/
Static Function fCriaSX1(cPerg)

	// Declaração das variáveis
	// Local nLinha  := 0
	Local aPerg := {}
	

	// Atribuição das informações
	aAdd(aPerg, {"X1_ORDEM", "X1_PERGUNT"              , "X1_VARIAVL", "X1_TIPO", "X1_TAMANHO"        , "X1_GSC", "X1_VALID"	,"X1_F3", "X1_VAR01", "X1_DEF01", "X1_DEF02", "X1_DEF03", "X1_DEF04" , "X1_DEF05"})
	aAdd(aPerg, {"01"      , "Local de estoque"        , "MV_CH1"    , "C"      , Len(SC6->C6_LOCAL)  , "G"     , "		"   	,"NNR"  , "MV_PAR01", ""        , ""        , ""        , ""         , ""        })
	aAdd(aPerg, {"02"      , "Data de Embarque De"     , "MV_CH2"    , "D"      , 8                   , "G"     , "		"   	,""     , "MV_PAR02", ""        , ""        , ""        , ""         , ""        })
	aAdd(aPerg, {"03"      , "Data de Embarque Ate"    , "MV_CH3"    , "D"      , 8                   , "G"     , "		"   	,""     , "MV_PAR03", ""        , ""        , ""        , ""         , ""        })
	aAdd(aPerg, {"04"      , "Caminho do arquivo"      , "MV_CH4"    , "C"      , 60                  , "G"     , "U_F0401503()",""     , "MV_PAR04", ""        , ""        , ""        , ""         , ""        })
	
	// 23/12/2021 Ticket 13209120	
	//DbSelectArea("SX1") // ARQUIVO DE PERGUNTAS
	// Cria Perguntas

	/*
	cPerg := PadR(cPerg, Len(SX1->X1_GRUPO))
	SX1->(dbSetOrder(1))

	For nLinha := 2 To Len(aPerg)
	
		If !SX1->(msSeek(cPerg + aPerg[nLinha, 1]))
			RecLock("SX1", .T.)
				Replace X1_GRUPO   With cPerg         // Caracter, Código chave de identificação da pergunta. Através deste código as perguntas são agrupadas em um conjunto
				Replace X1_ORDEM   With aPerg[nLinha][01] // Caracter, Ordem de apresentação das perguntas. A ordem é importante para a criação das variáveis de escopo PRIVATE MV_PAR??	
				Replace X1_PERGUNT With aPerg[nLinha][02] // Caracter, Rótulo com a descrição da pergunta no idioma Português
				Replace X1_PERSPA  With aPerg[nLinha][02] // Caracter, Rótulo com a descrição da pergunta no idioma Espanhol
				Replace X1_PERENG  With aPerg[nLinha][02] // Caracter, Rótulo com a descrição da pergunta no idioma Inglês
				Replace X1_VARIAVL With aPerg[nLinha][03] // Caracter, *** Não usado ***, porém preenchido por motivos de compatibilidade 
				Replace X1_TIPO    With aPerg[nLinha][04] // Caracter, Tipo de dado da pergunta, onde temos: C – Caracter/ L- Lógico/ D-Data/ N-Numérico/ M-Memo           
				Replace X1_TAMANHO With aPerg[nLinha][05] // Inteiro, Tamanho do Campo
				Replace X1_GSC     With aPerg[nLinha][06] // Caracter, Tipo de objeto a ser criado para essa pergunta, valores aceitos são: (G) Edit,(S)Text,(C) Combo,(R) Range,File,Expression ou (K)=Check. Caso campo esteja em branco é tratado como Edit. Objetos do tipo combo podem ter no máximo 5 itens.
				Replace X1_VALID   With aPerg[nLinha][07] // Caracter, Validação da Pergunta. A função deverá ser Function(para GDPs) ou User Function (Cliente) , Static Function não podem ser utilizadas.
				Replace X1_F3      With aPerg[nLinha][08] // Caracter, LookUp associado a pergunta
				Replace X1_VAR01   With aPerg[nLinha][09] // Caracter, Nome da variável criada para essa pergunta, no modelo MV_PARXXX, onde XXX é um sequencial numérico.
			MsUnLock()
		EndIf
	Next nLinha
	
	SX1->(DbCloseArea())   
	*/
	// 23/12/2021 Ticket 13209120
Return

/* {Protheus.doc} F0401503
Seleciona Caminho para o arquivo CSV
@Autor	Ronaldo Dantas
@Data	15/10/19
@Versão	12.1.23
@Return	Logico Verdadeiro
*/
User Function F0401503()    

MV_PAR04 := cGetFile("*.*", "Selecione uma pasta", 0,, .T., GETF_LOCALHARD + GETF_RETDIRECTORY, .F.)

Return(.T.)

Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)
	
	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL
	
	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10) 
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "003.1   MAX NASCIMENTO      144330  02/03/23 " + CHR(10) //Para item de Terceiro -> parâmetro exclusivo por filial
	cTexto += "003.0   MAX NASCIMENTO      144330  02/03/23 " + CHR(10) //Filial Ar Frio -> parâmetro exclusivo por filial
	cTexto += "002.1   MAX NASCIMENTO      141033  27/02/23 " + CHR(10) //Gerar com codigo de produto do canção
	cTexto += "002.0   MAX NASCIMENTO      141033  23/02/23 " + CHR(10) //Parametro para gerar arquivo com e sem peso variavel
	cTexto += "001.0   FREGADOLLI          135053  09/09/22 " + CHR(10) //Inclusão da opção peso variavel
	
	@ 10,70 SAY oSay PROMPT "F0401501" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
		
	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
