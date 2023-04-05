#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} F0401330
Rotinas para Gerar Pedido Filho
@Project    MIT044 - P04013 - GAP092 - Montagem Carga Mãe Filho
@Author     Mário Augusto Cavenaghi
@Since      16/08/2019
@Version    P12
@Type       Function
@Return     Nil
/*/

// *************************************************************************************************
//	Trata Pedidos Filhos
User Function F0401330(aPedidos, nAt, nOperation)

	Local lRet 			:= Alltrim(aPedidos[nAt, 1]) == "BR_PRETO"
	Local lConf			:= .T.
	Local cPedOrigem 	:= aPedidos[nAt, 3]
	Local lContinua		:= .T.
	
	Private oModel
	Private _nF0401330	:= nOperation	//	Será usado em outros Fontes
	Private _lGrvPV 	:= .F.	//	Será usado em outros Fontes
	Private _lEhPedExp	:= .F.
	Private dEntrega	:= CtoD( Space(8) )
	Private cPict		:= PesqPict("SC6","C6_ENTREG")
	Private cF3			:= ""	
	Private lRetPE 		:= .T.	
	Private oTelaPr
	Private oBtnConf
	Private oBtnCanc	
	Private oNewCod	



	If nOperation == 5 
		//Desabilitado a validação. Motivo: Quando temos mais de um item no pedido de venda, e apenas um deles foi gerado
		//carga mãe e filho e por algum motivo temos uma nova liberação do item que não está na carga mãe e filho.
		//O sistema não irá mais permitir estornar o item da carga mãe e filho. - Reinaldo Dias
		/*
		If aPedidos[nAt, 1] <> "BR_LARANJA"
			Alert("Somente pedidos com o status 'Processado' podem ser excluídos!")
			Return .F.
		Endif*/

		cPedOrigem := aPedidos[nAt, 3]

		// Verifica o status do carregamento
		PAZ->(dbSetOrder(3))	//	PAZ_FILIAL+PAZ_PEDIDO+PAZ_ITEM
		If PAZ->(dbSeek(xFilial("PAZ") + cPedOrigem))	//	Selecionar todas as transferências do Pedido
			PD5->(dbSetOrder(1)) //PD5_FILIAL+PD5_PEDMAE+PD5_ITEMAE+PD5_PEDCAR															
			While !PAZ->(Eof()) .And. PAZ->(PAZ_FILIAL + PAZ_PEDIDO) == xFilial("PAZ") + cPedOrigem
				
				If PD5->( DbSeek(xFilial("PD5") + cPedOrigem) )
					While !PD5->(Eof()) .And. PD5->(PD5_FILIAL + PD5_PEDMAE) == (xFilial("PD5") + cPedOrigem)
						If PD5->PD5_STATUS <> "1" // 1=Não Iniciado;2=Em Andamento;3=Liberado;4=NFE + Lib.PV;5=NFE
							Do Case
								Case PD5->PD5_STATUS == "2"	
									cStatusPD5 := '2=Em Andamento'
								Case PD5->PD5_STATUS == "3" 
									cStatusPD5 := '3=Liberado'
								Case PD5->PD5_STATUS == "4"
									cStatusPD5 := '4=NFE + Lib.PV'
								Case PD5->PD5_STATUS == "5"
									cStatusPD5 := '5=NFE'
							EndCase
							Help(,, 'Excluir',, 'Carregamento no status ' + cStatusPD5 + '. Não é possível excluir', 1, 0)
							lContinua := .F.
							Exit
						Endif

						PD5->(dbSkip())
					EndDo
				EndIf	

				If !lContinua
					Exit
				Endif

				PAZ->(dbSkip())
			Enddo

			If !lContinua
				Return .F.
			Endif
		Endif
	Endif

	If !lRet .And. nOperation == 4 .And. !aPedidos[nAt, 13] $ "01016|01027"
		Alert("Status não permitido para Gerar Pedido Filho!")
	Elseif Empty(aPedidos[nAt, 3])
		Alert("Não existe Pedido nessa seleção!")
	Else
		If nOperation == 4
			//Tela de confirmação da data de carregamento
			oTelaPr 	:= MSDialog():New( 092,232,180,603,"Data do Carregamento",,,.F.,,,,,,.T.,,,.T. )
			@ 004,003 MSGET oNewCod var dEntrega   SIZE 176,008 OF oTelaPr F3 "" PIXEL  VALID .T. PICTURE cPict 
			
			oBtnConf	:= TButton():New( 024,103,"&Confirmar",oTelaPr,{|| lConf:=fConfirm(aPedidos, nAt, nOperation), iif(lConf,oTelaPr:End(),"") },037,012,,,,.T.,,"",,,,.F. )
			oBtnCanc	:= TButton():New( 024,142,"&Cancelar",oTelaPr,{||oTelaPr:End()},037,012,,,,.T.,,"",,,,.F. )
			
			oNewCod:SetFocus() //Foco no objeto
			oTelaPr:lEscClose	:= .F.  
			oTelaPr:lCentered	:= .T.
			oTelaPr:Activate(,,,.T.)
		Else	
			fConfirm(aPedidos, nAt, nOperation)
		EndIf	

	Endif

Return(lRet)

/*/{Protheus.doc} fConfirm(aPedidos, nAt, nOperation)
//Rotina de confirmação e gravação no botão confirmar da msdialog                                                 
| Autor: Ronaldo Dantas                                             
| Data:  22/09/2020                                                 
| Desc:  Função de confirmação da rotina                            
| Obs.:                                                            
/*/
Static Function fConfirm(aPedidos, nAt, nOperation)
	Local lRet := .T.
	
	If nOperation == 4  // Gerar Ped.Filho
		If Empty(dEntrega)
			lRet := .F.
			Alert("Digite a data do carregamento!")
		Else
			If dEntrega < dDataBase
				Help(,,"HELP",, "Data do carregamento inválida!", 1, 0,,,,,,{"Preencha uma data do carregamento maior ou igual a data base!"})	
				lRet := .F.
			Endif
		Endif	
	Endif
	
	If lRet
		SC5->(dbSetOrder(1))	//	C5_FILIAL+C5_NUM
		SC5->(msSeek(xFilial() + aPedidos[nAt, 3]))
		SA1->(dbSetOrder(1))	//	A1_FILIAL+A1_COD+A1_LOJA
		SA1->(msSeek(xFilial() + aPedidos[nAt, 5] + aPedidos[nAt, 6]))

		If !Empty(SC5->C5_PEDEXP)
			_lEhPedExp := .T.
		Else
			_lEhPedExp := .F.
		Endif

		oModel := FwLoadModel("F0401330")
		
		oModel:SetOperation(4)
		oModel:Activate()

		oExecView := FwViewExec():New()
		oExecView:SetSource("F0401330")
		oExecView:SetCloseOnOK({|| .T.})
		oExecView:SetOperation(4)
		oExecView:SetModel(oModel)
		//oExecView:SetModal(.T.)
		oExecView:OpenView(.T.)
		If _lGrvPV	//	Houve alteração no F0401350
			If     nOperation == 4 // Processado
				aPedidos[nAt, 1] := "BR_LARANJA"
			ElseIf nOperation == 5 // Com Bloqueio
				aPedidos[nAt, 1] := "BR_PRETO"
			Endif
			aPedidos[nAt, 2] := LoadBitMap(GetResources(), aPedidos[nAt, 1])
		Endif		
	Endif
	
Return lRet


// *************************************************************************************************
//	Definição dos Modelos
Static Function ModelDef()

	Local oModel
	Local oStrP 	:= MdStrP()
	Local oStrI 	:= MdStrI()
	Local oStrT 	:= FwFormStruct(1, 'PAZ')
	Local bLinePre 	:= {|oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue| U_F0401342(oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue)}
	Local bPost		:= {|oMod| MntCargTOk(oModel)}
	Local bCommit	:= {|oMod| Iif(_nF0401330 == 1, .T., U_F0401350(oMod, _nF0401330))}
	
	//MPFORMMODEL():New(<cID >, <bPre >, <bPost >, <bCommit >, <bCancel >)-> NIL
	oModel := MpFormModel():New("M0401330", /*bPre*/, bPost,  bCommit)	

	//	Pedido
	oModel:AddFields('mPEDIDO', '', oStrP)
	oModel:GetModel( 'mPEDIDO'):SetDescription('Carga Mãe Filho')

	//	Grade com os Itens
	oModel:AddGrid( 'mITENS', 'mPEDIDO', oStrI)
	oModel:GetModel('mITENS'):SetDescription('Itens do Pedido de Venda')

	//	Grade das Transferências
	//oStrT:SetProperty("PAZ_FILIAL", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'xFilial("PAZ")'))
	oStrT:SetProperty("PAZ_PEDIDO", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'FwFldGet("C5_NUM")'))
	oStrT:SetProperty("PAZ_ITEORI", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'FwFldGet("WK_ITEM")'))
	oStrT:SetProperty("PAZ_PRODUT", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'FwFldGet("WK_PRODUTO")'))
	oStrT:SetProperty("PAZ_DESCR" , MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'FwFldGet("WK_DESCRIC")'))
	oStrT:SetProperty("PAZ_DESC1M", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'FwFldGet("WK_1_UM")'))
	oStrT:SetProperty("PAZ_DESC2M", MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'FwFldGet("WK_2_UM")'))

	oStrT:SetProperty("PAZ_LOCAL" , MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, 'Empty(FwFldGet("PAZ_LOCAL"))'))
	//oStrT:SetProperty("PAZ_QTDE1M", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, 'Empty(FwFldGet("PAZ_QTDE1M"))'))
	oStrT:SetProperty("PAZ_QTDE2M", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, 'Empty(FwFldGet("PAZ_QTDE2M"))'))
	
	oStrT:SetProperty('PAZ_QTDE1M' ,MODEL_FIELD_VALID, FWBuildFeature( STRUCT_FEATURE_VALID, 'u_F040134A()' ))
	
	oStrT:SetProperty('PAZ_FILDES' ,MODEL_FIELD_VALID, FWBuildFeature( STRUCT_FEATURE_VALID, 'u_F040134B()' ))

	oModel:AddGrid('mTRANS', 'mITENS', oStrT,,, bLinePre)
	oModel:GetModel('mTRANS'):SetDescription('Quantidade a Transferir')
	oModel:SetPrimaryKey({'C5_NUM', 'C5_CLIENTE', 'C5_LOJACLI'})
	oModel:SetRelation("mTRANS", { ;
		{"PAZ_FILIAL", "xFilial('PAZ')"}, ;
		{"PAZ_PEDIDO", "C5_NUM"        }, ;
		{"PAZ_ITEORI", "WK_ITEM"       }, ;
		{"PAZ_PRODUT", "WK_PRODUTO"    }},;
		PAZ->(IndexKey(1)))

Return oModel


// *************************************************************************************************
//	Modelo do Pedido
Static Function MdStrP()

	Local oStruct := FwFormModelStruct():New()

	oStruct:AddTable('SC5',, "Carga Mãe e Filho")

	oStruct:AddField('Pedido' , 'Pedido' , 'C5_NUM'    , 'C', TamSX3('C5_NUM'    )[1], 0,,,,, {|| SC5->C5_NUM    },,, .T.)
	oStruct:AddField('Cliente', 'Cliente', 'C5_CLIENTE', 'C', TamSX3('C5_CLIENTE')[1], 0,,,,, {|| SC5->C5_CLIENTE},,, .T.)
	oStruct:AddField('Loja'   , 'Loja'   , 'C5_LOJACLI', 'C', TamSX3('C5_LOJACLI')[1], 0,,,,, {|| SC5->C5_LOJACLI},,, .T.)
	oStruct:AddField('Nome'   , 'Nome'   , 'A1_NOME'   , 'C', TamSX3('A1_NOME'   )[1], 0,,,,, {|| SA1->A1_NOME   },,, .T.)

Return oStruct


// *************************************************************************************************
//	Modelo dos Itens
Static Function MdStrI()

	Local oStruct := FwFormModelStruct():New()
	Local nLenQtde := TamSX3("C6_QTDVEN")[1]

	oStruct:AddTable('SC6',, 'Itens do Pedido')

	oStruct:AddField(" "            , 'Legenda'             , 'WK_COR'    , 'C', 10                     , 0,,,,,,,, .T.)
	oStruct:AddField("Item"         , 'Item'                , 'WK_ITEM'   , 'C', 02                     , 0,,,,,,,, .T.)
	oStruct:AddField("Produto"      , 'Código do Produto'   , 'WK_PRODUTO', 'C', TamSX3("C6_PRODUTO")[1], 0,,,,,,,, .T.)
	oStruct:AddField("Descrição"    , 'Descrição do Produto', 'WK_DESCRIC', 'C', TamSX3("C6_DESCRI" )[1], 0,,,,,,,, .T.) //B1_DESC - ID577
	oStruct:AddField("1aUM"         , '1a. Unid. Mededa'    , 'WK_1_UM'   , 'C', 02                     , 0,,,,,,,, .T.)
	oStruct:AddField("Qtde.1aUM"    , 'Qtde. 1a. Unid. Med.', 'WK_QTDE1UM', 'N', nLenQtde               , 2,,,,,,,, .T.)
	oStruct:AddField("Qt.Transferir", 'Qtde. a Transferir'  , 'WK_QTRANSF', 'N', nLenQtde               , 2,,,,,,,, .T.)
	oStruct:AddField("Qt.Restante"  , 'Qtde. Restante'      , 'WK_QRESTAN', 'N', nLenQtde               , 2,,,,,,,, .T.)
	oStruct:AddField("Valor Total"  , 'Valor Total'         , 'WK_TOTAL'  , 'N', nLenQtde               , 2,,,,,,,, .T.)
	oStruct:AddField("2a.UM"        , '2a. Unid. Mededa'    , 'WK_2_UM'   , 'C', 02                     , 0,,,,,,,, .T.)
	oStruct:AddField("Qtde.2aUM"    , 'Qtde. 2a. Unid. Med.', 'WK_QTDE2UM', 'N', nLenQtde               , 2,,,,,,,, .T.)
	oStruct:AddField("Estoque"      , 'Em Estoque'          , 'WK_SALDO'  , 'N', nLenQtde               , 2,,,,,,,, .T.)

Return oStruct


// *************************************************************************************************
//	Montagem da Interface
Static Function ViewDef()

	Local oModel := ModelDef()
	Local oView  := FwFormView():New()
	Local oStrP  := VwStrP()
	Local oStrI  := VwStrI()
	Local oStrT  := FwFormStruct(2, 'PAZ', {|x| Alltrim(x) $ 'PAZ_SEQUEN, PAZ_ITEORI, PAZ_ITEM, PAZ_PRODUT, PAZ_DESCR, PAZ_FILDES, PAZ_LOCAL, PAZ_DESC1M, PAZ_QTDE1M, PAZ_DESC2M, PAZ_QTDE2M'})
	Local cLabel := "Gerar"

	If     _nF0401330 == 5
		cLabel := "Excluir"
	ElseIf _nF0401330 == 1
		cLabel := "Visualizar"
	Endif
	oView:SetModel(oModel)
	oView:SetDescription(cLabel)

	//	Pedido
	oView:AddField('vPEDIDO', oStrP, 'mPEDIDO')
	oView:CreateHorizontalBox('SUPERIOR', 70,, .T.)	//	Em PIXEL
	oView:SetOwnerView('vPEDIDO', 'SUPERIOR')

	//	Itens do Pedido
	oView:AddGrid('vITENS', oStrI, 'mITENS')
	oView:CreateHorizontalBox('MEIO', 40)
	oView:SetOwnerView('vITENS', 'MEIO')
	oView:EnableTitleView('vITENS', 'Itens do Pedido de Venda')

	//	Quantidade a Transferir
	oStrT:SetProperty('PAZ_SEQUEN', MVC_VIEW_ORDEM, '01')
	oStrT:SetProperty('PAZ_ITEORI', MVC_VIEW_ORDEM, '02')
	oStrT:SetProperty('PAZ_ITEM'  , MVC_VIEW_ORDEM, '03')
	oStrT:SetProperty('PAZ_PRODUT', MVC_VIEW_ORDEM, '04')
	oStrT:SetProperty('PAZ_DESCR' , MVC_VIEW_ORDEM, '05')
	oStrT:SetProperty('PAZ_FILDES', MVC_VIEW_ORDEM, '06')
	oStrT:SetProperty('PAZ_LOCAL' , MVC_VIEW_ORDEM, '07')
	oStrT:SetProperty('PAZ_DESC1M', MVC_VIEW_ORDEM, '08')
	oStrT:SetProperty('PAZ_QTDE1M', MVC_VIEW_ORDEM, '09')
	oStrT:SetProperty('PAZ_DESC2M', MVC_VIEW_ORDEM, '10')
	oStrT:SetProperty('PAZ_QTDE2M', MVC_VIEW_ORDEM, '11')

	oView:AddGrid('vTRANS', oStrT, 'mTRANS')
	oView:CreateHorizontalBox('INFERIOR', 60)
	oView:SetOwnerView('vTRANS', 'INFERIOR')
	oView:EnableTitleView('vTRANS', 'Quantidade a Transferir')
	oView:AddIncrementField('vTRANS', 'PAZ_SEQUEN')	// Campo Incremental

	oView:SetAfterViewActivate({| oView| F0401332(oView)})

Return oView


// *************************************************************************************************
//	Visualização do Pedido
Static Function VwStrP()

	Local oStruct := FwFormViewStruct():New()

	oStruct:AddField('C5_NUM'    , '01', 'Pedido' , 'Pedido' ,, 'C', '@!',,,.F.,,,,,,.T.,,)
	oStruct:AddField('C5_CLIENTE', '02', 'Cliente', 'Cliente',, 'C', '@!',,,.F.,,,,,,.T.,,)
	oStruct:AddField('C5_LOJACLI', '03', 'Loja'   , 'Loja'   ,, 'C', '@!',,,.F.,,,,,,.T.,,)
	oStruct:AddField('A1_NOME'   , '04', 'Nome'   , 'Nome'   ,, 'C', '@!',,,.F.,,,,,,.T.,,)

Return oStruct


// *************************************************************************************************
//	Visualização dos Itens do Pedido
Static Function VwStrI()

	Local oStruct 	:= FwFormViewStruct():New()
	Local nPect 	:= PesqPict("SC6","C6_QTDVEN") //"@E 999,999,999.99"

	oStruct:AddField('WK_COR'    , "01", " "            , 'Legenda'             ,, 'C', '@BMP',,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_ITEM'   , "02", "Item"         , 'Item'                ,, 'C', '@!'  ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_PRODUTO', "03", "Produto"      , 'Código do Produto'   ,, 'C', '@!'  ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_DESCRIC', "04", "Descrição"    , 'Descrição do Produto',, 'C', '@!'  ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_1_UM'   , "05", "1aUM"         , '1a. Unid. Medida'    ,, 'C', '@!'  ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_QTDE1UM', "06", "Qtde.1aUM"    , 'Qtde. 1a. Unid. Med.',, 'N', nPect ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_QTRANSF', "07", "Qt.Transferir", 'Qtde. a Transferir'  ,, 'N', nPect ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_QRESTAN', "08", "Qt.Restante"  , 'Qtde. Restante'      ,, 'N', nPect ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_TOTAL'  , "09", "Valor Total"  , 'Valor Total'         ,, 'N', nPect ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_2_UM'   , "10", "2a.UM"        , '2a. Unid. Medida'    ,, 'C', '@!'  ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_QTDE2UM', "11", "Qtde.2aUM"    , 'Qtde. 2a. Unid. Med.',, 'N', nPect ,,,.F.,,,,,,.T.,,)
	oStruct:AddField('WK_SALDO'  , "12", "Estoque"      , 'Em Estoque'          ,, 'N', nPect ,,,.F.,,,,,,.T.,,)

Return oStruct


// *************************************************************************************************
//	Montagem dos Itens Liberados
Static Function F0401331(cPedido)

	Local cQuery := ""
	Local aDados := {}
	Local nSaldo := nPos := 0
	
	//ACSJ - 19/10/2019  ---------------------------------------------------------------------------------------------------
	cQuery := "SELECT C6_ITEM, C6_PRODUTO, C6_DESCRI, C6_UM, C6_QTDVEN, C6_SEGUM, C9_QTDLIB2,                  " + CRLF
	cQuery += "       (CASE WHEN C9_BLEST = '99' THEN 0 ELSE C9_QTDLIB END)             AS WK_QTDLIB,          " + CRLF
	cQuery += "       (CASE WHEN C9_BLEST = '99' THEN 0 ELSE C9_QTDLIB END * C9_PRCVEN) AS WK_VALOR,           " + CRLF
	cQuery += "       (C6_QTDVEN - C6_QTDENT)                                           AS WK_SALDO            " + CRLF 
	cQuery += "  FROM      " + RetSqlName("SC6") + " C6 (NOLOCK)                                               " + CRLF
	cQuery += "  LEFT JOIN " + RetSqlName("SC9") + " C9 (NOLOCK) ON ( C9.C9_FILIAL  = '" + xFilial("SC9") + "' " + CRLF

	//	Segue ordem do Indice 1 do SC9
	cQuery += "   AND C9.C9_PEDIDO  = C6.C6_NUM      " + CRLF
	cQuery += "   AND C9.C9_ITEM    = C6.C6_ITEM     " + CRLF
	cQuery += "   AND C9.C9_PRODUTO = C6.C6_PRODUTO  " + CRLF
	cQuery += "   AND C9.D_E_L_E_T_ = ' '            " + CRLF
	
	If MV_PAR15 <> '5'
		cQuery += " AND C9.C9_BLEST = '02'  " + CRLF
	Endif
	
	cQuery += "   AND C9.C9_NFISCAL = ' ' ) " + CRLF

	//	Segue ordem do  Indice 1 do SC6
	cQuery += " WHERE C6.C6_FILIAL  = '" + xFilial("SC6") + "' " + CRLF
	cQuery += "   AND C6.C6_NUM     = '" + cPedido        + "' " + CRLF
	cQuery += "   AND C6.D_E_L_E_T_ = ' '                      " + CRLF

	cQuery += " ORDER BY 1, 2                                  " + CRLF
	//-------------------------------------------------------------------------------------------------------------[FIM ACSJ]
	
	
	PLSQuery(cQuery, "WK")

	SB2->(dbSetOrder(1))	//	B2_FILIAL+B2_COD+B2_LOCAL 
	While !WK->(Eof())
		If (nPos := aScan(aDados, {|x| x[2] == WK->C6_ITEM .And. x[3] == WK->C6_PRODUTO})) > 0
			aDados[nPos, 06] += WK->WK_QTDLIB
			aDados[nPos, 08] := Abs(Min(0, aDados[nPos, 12] - aDados[nPos, 06]))	//	Quantidade Bloqueada
			aDados[nPos, 09] += WK->WK_VALOR
			aDados[nPos, 11] += WK->C9_QTDLIB2
		Else
			SB2->(msSeek(xFilial() + WK->C6_PRODUTO))
			nSaldo := SaldoSB2() - U_F0401333(SB2->B2_FILIAL, WK->C6_PRODUTO)
			If nSaldo < 0
				nSaldo := 0
			Endif
			aAdd(aDados, { ;
				"", ;				// 01
				WK->C6_ITEM   , ;	// 02
				WK->C6_PRODUTO, ;	// 03
				WK->C6_DESCRI , ;	// 04
				WK->C6_UM     , ;	// 05
				WK->WK_QTDLIB , ;	// 06
				0, ;				// 07
				WK->WK_QTDLIB , ;  	// 08 Abs(Min(0, nSaldo - WK->WK_QTDLIB)), ; 	//	Se existir saldo retorna ZERO ou Quantidade Bloqueada
				WK->WK_VALOR  , ;	// 09
				WK->C6_SEGUM  , ;	// 10
				WK->C9_QTDLIB2, ;	// 11
				Max(0, nSaldo)} )	// 12 Para inibir Saldo Negativo
			nPos := Len(aDados)
		Endif
		If aDados[nPos, 06] == 0
			aDados[nPos, 01] := "BR_AMARELO" // Integrado
			aDados[nPos, 07] := WK->C6_QTDVEN
		Elseif WK->WK_SALDO == 0
			aDados[nPos, 01] := "BR_LARANJA" // Processado
		Else
			aDados[nPos, 01] := Iif( (aDados[nPos, 08] > 0 .OR. aDados[nPos, 07] == 0) , 'BR_PRETO', 'BR_VERDE')	//	COM ou SEM Bloqueio
		Endif
		WK->(dbSkip())
	Enddo
	WK->(dbCloseArea())

Return(aDados)


// *************************************************************************************************
//	Popula os Grids
Static Function F0401332(oView)

	Local oModel := oView:GetModel()
	Local oItens := oModel:GetModel("mITENS")
	Local oTrans
	Local aCabec := oItens:GetStruct():GetFields()
	Local aDados := F0401331(SC5->C5_NUM)
	Local nD     := 0
	Local nC     := 0

	PAZ->(dbSetOrder(1))	//	PAZ_FILIAL+PAZ_PEDIDO+PAZ_ITEORI+PAZ_SEQUEN
	If IsInCallStack("U_F0401320")
		For nD := 1 To Len(aDados)
			If nD > 1
				If oItens:AddLine() <> nD
					Alert('Nao incluiu linha no Modelo [mITENS] ' + CRLF + oModel:getErrorMessage()[6])
					Exit
				Endif
			Endif
			For nC := 1 To Len(aCabec)	//	Carrega os dados do Item do Pedido
				oItens:LoadValue(aCabec[nC, 3], aDados[nD, nC])
			Next

			//	Montagem dos dados a Transferir
			oTrans := oModel:GetModel("mTRANS")
			PAZ->(msSeek(xFilial() + FwFldGet("C5_NUM") + oItens:GetValue("WK_ITEM")))
			If PAZ->(Deleted())	//	As vezes está posicionando no deletado
				Set Deleted On	//	Bloqueia os deletados
				PAZ->(msSeek(xFilial() + FwFldGet("C5_NUM") + oItens:GetValue("WK_ITEM")))
			Endif
			If PAZ->(Eof())
				oTrans:LoadValue("PAZ_FILIAL", xFilial("PAZ"))
				oTrans:LoadValue("PAZ_PEDIDO", FwFldGet("C5_NUM"))
				oTrans:LoadValue("PAZ_ITEORI", oItens:GetValue("WK_ITEM"))
				oTrans:LoadValue("PAZ_PRODUT", oItens:GetValue("WK_PRODUTO"))
				oTrans:LoadValue("PAZ_DESCR" , oItens:GetValue("WK_DESCRIC"))
				oTrans:LoadValue("PAZ_DESC1M", oItens:GetValue("WK_1_UM"))
				oTrans:LoadValue("PAZ_DESC2M", oItens:GetValue("WK_2_UM"))
			Else
				nC := 0
				While !PAZ->(Eof()) .And. PAZ->(PAZ_FILIAL + PAZ_PEDIDO + PAZ_ITEORI) = xFilial("PAZ") + FwFldGet("C5_NUM") + oItens:GetValue("WK_ITEM")
					nC++
					If oTrans:Length() < nC
						oTrans:AddLine()
					Else
						oTrans:GoLine(nC)
					Endif
					oTrans:LoadValue("PAZ_FILIAL", xFilial("PAZ"))
					oTrans:LoadValue("PAZ_PEDIDO", FwFldGet("C5_NUM"))
					oTrans:LoadValue("PAZ_SEQUEN", PAZ->PAZ_SEQUEN)
					oTrans:LoadValue("PAZ_ITEORI", PAZ->PAZ_ITEORI)
					oTrans:LoadValue("PAZ_ITEM"  , PAZ->PAZ_ITEM)
					oTrans:LoadValue("PAZ_PRODUT", oItens:GetValue("WK_PRODUTO"))
					oTrans:LoadValue("PAZ_DESCR" , oItens:GetValue("WK_DESCRIC"))
					oTrans:LoadValue("PAZ_FILDES", PAZ->PAZ_FILDES)
					oTrans:LoadValue("PAZ_LOCAL" , PAZ->PAZ_LOCAL)
					oTrans:LoadValue("PAZ_DESC1M", oItens:GetValue("WK_1_UM"))
					oTrans:LoadValue("PAZ_QTDE1M", PAZ->PAZ_QTDE1M)
					oTrans:LoadValue("PAZ_DESC2M", oItens:GetValue("WK_2_UM"))
					oTrans:LoadValue("PAZ_QTDE2M", PAZ->PAZ_QTDE2M)
					PAZ->(dbSkip())
				Enddo
			Endif
		Next

		oItens:SetNoInsertLine(.T.)
		oItens:SetNoDeleteLine(.T.)
		If _nF0401330 <> 4 // 1=Visualizar, 4=Gerar Ped.Filho, 5=Excluir Ped.Filho
			oTrans:SetNoInsertLine(.T.)
			oTrans:SetNoDeleteLine(.T.)
			oTrans:SetNoUpdateLine(.T.)
		Elseif _nF0401330 == 4
			If _lEhPedExp // se for pedido de exportacao
				oTrans:SetNoInsertLine(.T.)
				oTrans:SetNoDeleteLine(.T.)
			Endif
		Endif

		oItens:GoLine(1)
		oView:ReFresh()
	Endif

Return


// *************************************************************************************************
//	Retorna Quantidade do Produto, em uso nos pedido
User Function F0401333(cFilAtu, cProduto)

	Local cQuery := ""
	Local nQtdLib := 0

	cQuery := "SELECT SUM(C9_QTDLIB) AS QTDLIB " + CRLF
	cQuery += "  FROM " + RetSqlName("SC9") + " (NOLOCK) " + CRLF
	cQuery += " WHERE C9_FILIAL  = '" + cFilAtu  + "' " + CRLF
	cQuery += "   AND C9_PRODUTO = '" + cProduto + "' " + CRLF
	cQuery += "   AND C9_XPROCES = '1' " + CRLF
	cQuery += "   AND C9_NFISCAL = ' ' " + CRLF
	cQuery += "   AND C9_BLEST  <> ' ' " + CRLF
	cQuery += "   AND D_E_L_E_T_ = ' ' " + CRLF
	PLSQuery(cQuery, "xSC9")
	nQtdLib := xSC9->QTDLIB
	xSC9->(dbCloseArea())

Return(nQtdLib)


/*/{Protheus.doc} MntCargTOk

Pos-validação do model

@type function
@version 
@author fabio.cazarini
@since 08/08/2020
@param oModel, object, param_description
@return return_type, return_description
/*/
Static Function MntCargTOk(oModel)
	Local oItens    := oModel:GetModel("mITENS")
	Local oTrans    := oModel:GetModel("mTRANS")
	Local lRet 		:= .T.
	Local nItens	:= 0
	Local nTrans	:= 0
	Local cFilDes	:= ""
	Local aFilDes	:= {}
	Local aFilDes2	:= {}
	Local nQtde1M	:= 0
	Local cMsgPro	:= ""
	Local cMsgSol	:= ""
	Local nLinIt	:= 0
	Local nLinTr	:= 0
	Local cMoedaOr	:= SC5->C5_MOEDA
	Local nTxSM2	:= 0
    Local cSimb2	:= SuperGetMV("MV_SIMB2",.T.,"")
	Local cSimb3	:= SuperGetMV("MV_SIMB3",.T.,"")
	Local cSimb4	:= SuperGetMV("MV_SIMB4",.T.,"")
	Local cSimb5	:= SuperGetMV("MV_SIMB5",.T.,"")
	Local cSimbol	:= ""
	Local cQuery 	:= "" //Incluido por Tiago Castilho
	Local cPedOrig  := "" //Incluido por Tiago Castilho

	If _nF0401330 == 4 // 1=Visualizar, 4=Gerar Ped.Filho, 5=Excluir Ped.Filho

		FOR nItens := 1 To oItens:Length() // itens do pedido original
			oItens:GoLine(nItens)

			If !oItens:IsDeleted()
				nLinIt++

				FOR nTrans := 1 To oTrans:Length() // itens do pedido de transferência
					oTrans:GoLine(nTrans)

					If !oTrans:IsDeleted()
						nLinTr++

						cFilDes  := oTrans:GetValue("PAZ_FILDES")
						nQtde1M	 := oTrans:GetValue("PAZ_QTDE1M")
						cProduto := oTrans:GetValue("PAZ_PRODUT")
						cPedOrig := oTrans:GetValue("PAZ_PEDIDO") //Incluido por Tiago Castilho

						//Incluido por Tiago Castilho
						cQuery 		:= " SELECT PAZ_PEDDES, PAZ_FILDES, PAZ_PEDIDO "
						cQuery 		+= " FROM "+RetSqlName("PAZ")+" PAZ "
						cQuery 		+= " WHERE PAZ.D_E_L_E_T_ = ' ' "
						cQuery 		+= " AND PAZ_FILIAL = '" +xFilial("PAZ") + "' "
						cQuery 		+= " AND PAZ_PEDIDO = '" + cPedOrig      + "' "
						cQuery 		+= " AND PAZ_FILDES = '" + cFilDes       + "' "								
					
						cQuery		:= ChangeQuery(cQuery)
						cAliasQry	:= MPSysOpenQuery(cQuery)

						If !(cAliasQry)->(Eof()) //Incluido por Tiago Castilho
							cMsgPro := "Já existe pedido filho na filial de carregamento <b>" + Alltrim(cFilDes)
							cMsgPro +=  "</b>, Para o pedido mãe Nº " +  Alltrim(cPedOrig)
							cMsgSol := "Selecione uma outra filial de carregamento"
							lRet	:= .F.
							EXIT
						Else
						
							// Se o pedido origem for de exportação (C5_PEDEXP preenchido), não permite mais de 1 local de embarque
							If _lEhPedExp
								If aScan( aFilDes, cFilDes) == 0 // se não encontrou a filial destino 
									If Len( aFilDes ) == 0		
										// primeiro item	
										aadd( aFilDes, cFilDes ) 
									Else
										// tem uma filial destino diferente
										cMsgPro := "Pedidos de exportação podem ter somente um único local de embarque"
										cMsgSol	:= "Corrija a filial de coleta do pedido filho e confirme novamente"
										lRet	:= .F.
										EXIT
									Endif	
								Endif	
								
								// valida taxa de cambio
								//cProduto 	:= oTrans:GetValue("PAZ_PRODUT")	
								cLocal		:= oTrans:GetValue("PAZ_LOCAL")			
								nCusto 		:= 0

								SB2->(dbSetOrder(1)) //	B2_FILIAL+B2_COD+B2_LOCAL
								If SB2->(dbSeek(cFilDes + cProduto + cLocal))
									nCusto := SB2->B2_CM1
								EndIf
							
								If nCusto == 0
									If cMoedaOr > 1 // se for moeda estrangeira, busca a taxa do dia para gerar o pedido filho em moeda nacional (R$)
										nTxSM2 	:= 0
										cSimbol	:= ""
										SM2->( dbSetOrder(1))
										If SM2->( dbSeek(  DtoS( dDataBase ) ) )
											If cMoedaOr == 2
												nTxSM2 	:= SM2->M2_MOEDA2
												cSimbol	:= cSimb2
											Elseif cMoedaOr == 3
												nTxSM2 	:= SM2->M2_MOEDA3
												cSimbol	:= cSimb3
											Elseif cMoedaOr == 4
												nTxSM2 	:= SM2->M2_MOEDA4
												cSimbol	:= cSimb4
											Elseif cMoedaOr == 5
												nTxSM2 	:= SM2->M2_MOEDA5
												cSimbol	:= cSimb5
											Endif
										Endif

										If nTxSM2 == 0
											cMsgPro := "Não foi possível localizar a taxa da moeda " + cSimbol
											cMsgSol	:= "Cadastre a taxa da moeda"
											lRet	:= .F.
											EXIT
										Endif
									Endif
								Endif
							Else
								//Verifica se existe o mesmo local de embarque mais de uma vez para o mesmo produto.
								IF !Empty(cFilDes)
									If (nPos := Ascan(aFilDes2,{|x| x[1]+x[2] == cFilDes+cProduto })) == 0
										AAdd(aFilDes2,{cFilDes,cProduto})
									Else
										cMsgPro := "Permitido apenas uma filial de coleta por produto."
										cMsgSol	:= "Corrija a filial de coleta <b>"+cFilDes+"</b> ou ajuste o pedido mãe com apenas um produto por item (linha)."
										lRet	:= .F.
										EXIT
									Endif
								Endif	
							Endif
						Endif
					Endif
				NEXT nTrans

				If !lRet
					EXIT
				Endif
			Endif	
		NEXT nItens

		// posiciona na linha 1 caso tenha 1 ou mais linhas
		If nLinTr >= 1
			oItens:GoLine(1)
		Endif
		If nLinTr >= 1
			oTrans:GoLine(1)
		Endif	

		If !lRet
			Help("", , "ATENÇÃO", "MntCargTOk", cMsgPro,1,,,,,,,{cMsgSol} )  
		Endif		
	Endif

Return lRet
