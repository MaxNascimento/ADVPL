#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} F0404540
Gerenciamento de Movimentação de Veiculo
@author Sergio Compain
@since 02/10/19
@project	0000032563

@history 	30/09/2019, Sergio Compain, Desenvolvimento inicial (MIT044 - P04045 - IT05,CST07,CST10 e CST11 - Fluxo de Pesagem)
/*/
User Function F0404540()
	Local oBrowse := FWMBrowse():New()

	oBrowse:SetAlias('PC2')
	oBrowse:SetDescription('Gerenciamento de Movimentação de Veiculo')
	oBrowse:SetOnlyFields( { 'PC2_CTRLE', 'PC2_TIPMOV', 'PC2_MOVIM', 'PC2_PLACA', 'PC2_SENTID','PC2_CLIFOR', 'PC2_NMCLFR' , 'PC2_NMOTO', 'PC2_DATINC', 'PC2_DATCLS'} )
	oBrowse:AddLegend( "PC2_STATUS  == 'A'", "BR_VERDE"   	, X3CboxDesc( "PC2_STATUS", "A" ) ) //"Aberto"      )
	oBrowse:AddLegend( "PC2_STATUS  == 'P'", "BR_AMARELO" 	, X3CboxDesc( "PC2_STATUS", "P" ) ) //"1o. Pesagem" )
	oBrowse:AddLegend( "PC2_STATUS  == 'S'", "BR_VIOLETA" 	, X3CboxDesc( "PC2_STATUS", "S" ) ) //"2o. Pesagem" )
	oBrowse:AddLegend( "PC2_STATUS  == 'B'", "BR_PINK" 		, X3CboxDesc( "PC2_STATUS", "B" ) ) //"2o. Pesagem - Bloqueada" )
	oBrowse:AddLegend( "PC2_STATUS  == 'I'", "BR_LARANJA" 	, X3CboxDesc( "PC2_STATUS", "I" ) ) //"Aguard.Integra" )
	oBrowse:AddLegend( "PC2_STATUS  == 'C'", "BR_AZUL" 	    , X3CboxDesc( "PC2_STATUS", "C" ) ) //"Concluido"   )
	oBrowse:AddLegend( "PC2_STATUS  == 'D'", "BR_PRETO" 	, X3CboxDesc( "PC2_STATUS", "D" ) ) //"Doc. Fiscal" )
	oBrowse:AddLegend( "PC2_STATUS  == 'E'", "BR_VERMELHO"  , X3CboxDesc( "PC2_STATUS", "E" ) ) //"Cancelado"   )
	oBrowse:SetMenuDef("F0404540")

	oBrowse:Activate()

Return


Static Function MenuDef()

	Local aRotina := {}

	//Adicionando opções
	ADD OPTION aRotina TITLE 'Pesquisar'  					ACTION 'PesqBrw'          	OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE 'Visualizar' 					ACTION 'VIEWDEF.F0404540' 	OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'   	 				ACTION 'VIEWDEF.F0404540' 	OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    					ACTION 'VIEWDEF.F0404540' 	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir Ticket'  			ACTION 'U_F0404547' 	  	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Gerar Doc.Fiscal' 			ACTION 'U_F0404545'       	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Cancelar Movimentação' 		ACTION 'U_F0404542'   	  	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Reenvio Canc.eData Fr.Vivo' 	ACTION 'U_F040454C' 		OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Reenvio Pesagem'  			ACTION 'U_F0404546'   	 	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Enviar Carregamento eData'  	ACTION 'U_F0404548'  		OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Cancelar Int. eData Exped'  	ACTION 'U_F0407110'  		OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Reabrir Carga eData'  		ACTION 'U_F0407710'  		OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Executa Integrações'  		ACTION 'U_F0409910'  		OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Justifica Liberação'  		ACTION 'U_F0404902'  		OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Receber Pesagem eData'		ACTION 'U_F0404564'  		OPERATION 4 ACCESS 0
Return aRotina

Static Function ModelDef()

	Local oStruMod 	:= FWFormStruct(1,'PC2')
	Local oModel	:= MPFormModel():New( 'Movimentação de Veiculo' ,{|oModel| F0404540I( oModel ) } , {|oModel| F0404540D( oModel ) } , {|oModel| F0404540V( oModel ) }, {|oModel| F0404540C( oModel ) } )
	Local cVCliFor  := ""
	Local bVCliFor
	Local cVLojFor  := ""
	Local bVLojFor


	oModel:AddFields('MASTER',, oStruMod)
	oModel:SetPrimaryKey({"xFilial('PC2')", "PC2_CTRLE" })
	oModel:SetDescription('Movimentação de Veiculo')
	oModel:GetModel('MASTER'):SetDescription('Movimentação de Veiculo')
	oModel:SetVldActivate({|oModel| F0404540A( oModel ) })


	cVCliFor := "IIF(M->PC2_SENTID == 'E',ExistCpo('SA2',M->PC2_CLIFOR),ExistCpo('SA1',M->PC2_CLIFOR))"
	bVCliFor := FWBuildFeature( STRUCT_FEATURE_VALID, cVCliFor )
	oStruMod:SetProperty( 'PC2_CLIFOR', MODEL_FIELD_VALID,bVCliFor)

	cVLojFor := "IIF(M->PC2_SENTID == 'E',ExistCpo('SA2',M->PC2_CLIFOR+M->PC2_LOJA),ExistCpo('SA1',M->PC2_CLIFOR+M->PC2_LOJA))"
	bVLojFor := FWBuildFeature( STRUCT_FEATURE_VALID, cVLojFor )
	oStruMod:SetProperty( 'PC2_LOJA', MODEL_FIELD_VALID,bVLojFor)


Return oModel

Static Function ViewDef()

	Local oModel 	:= ModelDef()
	Local oStruView := FWFormStruct(2,'PC2')
	Local oView		:= FWFormView():New()

	oView:SetModel(oModel)
	oView:AddField('VIEW_MASTER', oStruView, 'MASTER')
	oView:CreateHorizontalBox('SUPERIOR', 100 )
	oView:SetOwnerView('VIEW_MASTER', 'SUPERIOR')

	oView:AddUserButton( "[F8]  Movimento"		, "", { | x | U_F0404541( oModel , "VIEW" , M->PC2_CTRLE, M->PC2_OPERA, M->PC2_TIPMOV , oModel:GetOperation() , cFilAnt, M->PC2_NFENTR , M->PC2_STATUS) } )
	oView:AddUserButton( "[F9]  NF Ref."		, "", { | x | U_F0404501(oModel) } )
	oView:AddUserButton( "[F10] Pesagem"		, "", { | x | U_F0404544(oModel) } )
	oView:AddUserButton( "[F11] Carga/Seq"		, "", { | x | U_F0404560(oModel) } )
	oView:AddUserButton( "[F12] Viagem"			, "", { | x | U_F0404561(oModel) } )

	oStruView:RemoveField('PC2_USRINC')
	oStruView:RemoveField('PC2_HORINC')
	oStruView:RemoveField('PC2_USRCLS')
	oStruView:RemoveField('PC2_HORCLS')
	oStruView:RemoveField('PC2_USRCAN')
	oStruView:RemoveField('PC2_HORCAN')
	oStruView:RemoveField('PC2_USRAUT')


Return oView

Static Function F0404540A( oModel )

	Local lRet          := .T.
	Local nOperation    := oModel:GetOperation()

	If nOperation == MODEL_OPERATION_UPDATE
		If PC2->PC2_STATUS == "E"
			lRet := .f.
			Help(NIL, NIL, "Tipo de Movimentação", NIL, "A movimentação está cancelada" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Movimentações canceladas não podem ser alteradas"})
		Elseif PC2->PC2_STATUS == "C"
			lRet := .f.
			Help(NIL, NIL, "Tipo de Movimentação", NIL, "A movimentação está concluída" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Movimentações concluídas não podem ser alteradas"})
		EndIf
	EndIf

	If lRet
		U_F04045KEY(oModel,.T.)
	EndIf

Return lRet


Static Function F0404540I( oModel )

	Local lRet          := .T.

Return lRet


Static Function F0404540V( oModel )

	Local lRet          := .T.
	Local nOperation    := oModel:GetOperation()

	Begin Transaction

		If nOperation == MODEL_OPERATION_UPDATE

		EndIf

		If nOperation == MODEL_OPERATION_DELETE
			F04045DEL(PC2->PC2_CTRLE)
		EndIf

		FwFormCommit( oModel )

	End Transaction

	U_F04045KEY(oModel,.F.)

	FwModelActive( oModel, .T. )

Return lRet

Static Function F0404540C( oModel )

	Local lRet          := .T.
	Local nOperation    := oModel:GetOperation()

	If nOperation == MODEL_OPERATION_INSERT
		F04045DEL(M->PC2_CTRLE)
	EndIf

	If nOperation == MODEL_OPERATION_UPDATE
		U_F04045RC(PC2->PC2_CTRLE,PC2->PC2_PESLIQ,PC2->PC2_OPERA)
	EndIf

	U_F04045KEY(oModel,.F.)

	FwModelActive( oModel, .T. )

	FWFORMCANCEL(oModel)

Return lRet

//Função para fazer a validação antes de salvar as alterações
Static Function F0404540D( oModel )
	Local aAreaAtu 	:= getarea()
	Local aAreaDK0	:= DK0->( GetArea() )
	Local aAreaDAK	:= DAK->( GetArea() )
	Local lRet      := .T.
	Local nOperat	:= oModel:GetOperation()
	Local cLorenz	:= IIF(FindFunction("U_fOpMovim"),U_fOpMovim("LORENZ")	, SuperGetMV("FS_C040457",, "") )
	Local cLenha	:= IIF(FindFunction("U_fOpMovim"),U_fOpMovim("LENHA")	, SuperGetMV("FS_C040458",, "") )
	Local cViagem 	:= ""
	Local cCarga	:= ""
	Local cSQCar	:= ""
	Local cTransp	:= ""
	Local cMotor	:= ""
	Local cPlaca1	:= ""
	Local cPlaca2	:= ""
	Local cPlaca3	:= ""
	Local lContinua	:= .F.
	Local cOMSFilA4	:= Alltrim(OMSXGETFIL("SA4"))
	Local cFilPed	:= ""
	Local cCodCli	:= ""
	Local cCliLoj	:= ""
	Local cContei   := ""

	If nOperat == MODEL_OPERATION_INSERT

		IF oModel:GetValue("MASTER","PC2_SENTID") == "E"
			IF (oModel:GetValue("MASTER","PC2_OPERA") $ cLenha .OR. oModel:GetValue("MASTER","PC2_OPERA") $ cLorenz)

				IF Empty(oModel:GetValue("MASTER","PC2_NOTA")) .AND. lRet
					Help(,,"[F0404540D] Erro na Inclusão.",,"Campo de Nota Fiscal para movimentação de entrada é obrigatório.", 1, 0,,,,,,{"Preencher Campo de Nota Fiscal"})
					lRet := .F.
				EndIF

				IF Empty(oModel:GetValue("MASTER","PC2_SERIE")) .AND. lRet
					Help(,,"[F0404540D] Erro na Inclusão.",,"Campo de Série da Nota Fiscal para movimentação de entrada é obrigatório.", 1, 0,,,,,,{"Preencher Campo de Série da Nota Fiscal"})
					lRet := .F.
				EndIF

				IF Empty(oModel:GetValue("MASTER","PC2_ESPECI")) .AND. lRet
					Help(,,"[F0404540D] Erro na Inclusão.",,"Campo de Especie da Nota Fiscal para movimentação de entrada é obrigatório.", 1, 0,,,,,,{"Preencher Campo de Especie da Nota Fiscal"})
					lRet := .F.
				EndIF

				IF Empty(oModel:GetValue("MASTER","PC2_DTEMIS")) .AND. lRet
					Help(,,"[F0404540D] Erro na Inclusão.",,"Campo de Data Emissão da Nota Fiscal para movimentação de entrada é obrigatório.", 1, 0,,,,,,{"Preencher Campo de Data de Emissão da Nota Fiscal"})
					lRet := .F.
				EndIF
			EndIF	
		EndIF

		If lRet
			cViagem 	:= oModel:GetValue("MASTER","PC2_VIAGEM")
			cCarga		:= oModel:GetValue("MASTER","PC2_CARGA")
			cSQCar		:= oModel:GetValue("MASTER","PC2_SQCAR")
			lContinua	:= .F.
			IF !Empty(cViagem)
				If LocDK0(cViagem)
					cTransp   	:= padr( SubStr(Alltrim(DK0->DK0_TRANSP),1,Len(Alltrim(DK0->DK0_TRANSP))-Len(cOMSFilA4)) , len(SA4->A4_COD) )
					cMotor		:= DK0->DK0_XMOTOR
					cPlaca1		:= DK0->DK0_PLACA
					cPlaca2		:= DK0->DK0_XVEIC2
					cPlaca3		:= DK0->DK0_XVEIC3
					lContinua	:= .T.
				Endif
			Else
				DAK->(dbsetOrder(1))
				If DAK->(MsSeek(xFilial("DAK")+cCarga+cSQCar))
					cTransp		:= DAK->DAK_TRANSP
					cMotor		:= DAK->DAK_MOTORI
					cPlaca1		:= DAK->DAK_CAMINH
					cPlaca2		:= DAK->DAK_VEIC2
					cPlaca3		:= DAK->DAK_VEIC3
					lContinua 	:= .T.
				Endif
			Endif
			If lContinua
				If 	Alltrim(oModel:GetValue("MASTER","PC2_TRANSP")) <> Alltrim(cTransp) .or. ;
					Alltrim(oModel:GetValue("MASTER","PC2_MOTOR")) <> Alltrim(cMotor) .or. ;
					Alltrim(oModel:GetValue("MASTER","PC2_PLACA")) <> Alltrim(cPlaca1) .or. ;
					Alltrim(oModel:GetValue("MASTER","PC2_REBOQ1")) <> Alltrim(cPlaca2) .or. ;
					Alltrim(oModel:GetValue("MASTER","PC2_REBOQ2")) <> Alltrim(cPlaca3)

					Help(,,"[F0404540D] Erro na Inclusão.",,"Viagem vinculada não corresponde aos dados informados no processo!",;
							1, 0,,,,,,{"Preencha os campos transportadora, motorista, placa, reboque 1 e reboque 2, de acordo com a viagem ou carga"})
					lRet := .F.
				Endif
			Endif
		Endif
	EndIF

	If lRet
		If nOperat == MODEL_OPERATION_INSERT .or. nOperat == MODEL_OPERATION_UPDATE
			cViagem := oModel:GetValue("MASTER","PC2_VIAGEM")
			IF !Empty(cViagem)
				If LocDK0(cViagem)
					If lRet
						cFilPed := POSICIONE("DK1", 1, DK0->(DK0_FILIAL+DK0_REGID+DK0_VIAGID), "DK1_FILPED")

						If Alltrim(cFilPed) <> Alltrim(cfilant)
							Help(,,"[F0404540D] Erro na Inclusão da viagem.",,"A filial " + cFilPed + " do(s) pedido(s) da viagem vinculada não corresponde à filial corrente (logada)!",;
									1, 0,,,,,,{"Selecione uma viagem com pedido(s) da filial " + cfilant})
							lRet := .F.
						Endif
					Endif
					If lRet
						If DK0->DK0_SITINT <> "2"
							Help(,,"[F0404540D] Erro na Inclusão da viagem.",,"A viagem " + cViagem + " não está com status de liberada!",;
									1, 0,,,,,,{"Selecione uma viagem liberada"})
							lRet := .F.
						Endif
					Endif
				Endif
			Endif

			If oModel:GetValue("MASTER","PC2_SENTID") == "S"
				cCodCli	:= oModel:GetValue("MASTER","PC2_CLIFOR")
				cCliLoj	:= oModel:GetValue("MASTER","PC2_LOJA")
				cContei := oModel:GetValue("MASTER","PC2_XCONTE")

				If AllTrim(cContei) == "-"
					cContei := " "
					oModel:SetValue("MASTER","PC2_XCONTE"," ")
				Endif

				DBSelectArea("SA1")
				SA1->(DBSetOrder(1))
				SA1->(DBSeek(xFilial("SA1")+cCodCli+cCliLoj))

				If SA1->A1_TIPO == "X"
					If Empty(cContei) .AND. lRet
						Help(,,"[F0404540D] Erro na Inclusão.",,"Para cliente de Exportação, o campo Nr.Container é obrigatório.", 1, 0,,,,,,{"Preencher Campo Nr.Container"})
						lRet := .F.
					EndIf
				Endif
			Endif
		Endif
	Endif

	RestArea(aAreaDK0)
	RestArea(aAreaDAK)
	RestArea(aAreaAtu)

Return lRet


Static Function F04045DEL(cCTRLE)

	Local aAreaAtu := getarea()

	dbSelectArea("PAE")
	PAE->(dbSetOrder(1))
	If PAE->(dbSeek(xFilial("PAE")+cCTRLE))
		While !Eof() .and. PAE->PAE_FILIAL == xFilial("PAE") .AND. PAE->PAE_CTRLE == cCTRLE
			PAE->(RecLock("PAE",.f.))
			PAE->(dbDelete())
			PAE->(MsUnlock())
			PAE->(dbSkip())
		End
	EndIf

	RestArea(aAreaAtu)

Return()

//CONSULTA PADRAO FS0445 (Cliente/Fornecedor)
User Function F040454A()

	Local AreaAtu := getarea()

	Public cCodRet := criavar("A1_COD")
	Public cLojRet := criavar("A1_LOJA")

	If M->PC2_SENTID == "E"
		ConPad1(,,,"SA2")
	Else
		ConPad1(,,,"SA1")
	EndIf

	If !Empty(aCpoRet)
		cCodRet := aCpoRet[1]
		cLojRet := aCpoRet[2]
	EndIf

	Restarea(AreaAtu)

Return(.t.)

//Valida se o Tipo de Moiventação esta Ativo
User Function F040454B(cTipoMov)

	Local AreaAtu 	:= getarea()
	Local lOk	  	:= .t.
	Local oModel    := FWModelActive()
	//Local nOperation := oModel:GetOperation()
	//Local oView      := FWViewActive()
	//Local cOpcVld   := Alltrim(SuperGetmv("FS_C040451",.F.,"3,4"))


	dbSelectArea("PBS")
	PBS->(dbSetOrder(1))
	If PBS->(dbSeek(xFilial("PBS")+cTipoMov))
		If PBS->PBS_STATUS == "I"
			Help(NIL, NIL, "Tipo de Movimentação", NIL, " Tipo de Movimentação esta Inativo" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Informe outro Tipo de Movimentação"})
			lOk := .f.
		EndIf
		//If lOk
		//	If PBS->PBS_OPERA $ cOpcVld
		//		Help(NIL, NIL, "Tipo de Movimentação", NIL, " Tipo de Movimentação não habilitada para essa rotina conforme o parametro 'FS_C040451'" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Informe outro Tipo de Movimentação"})
		//		lok := .f.
		//	EndIf
		//EndIf
	EndIf

	oModel:LoadValue("MASTER","PC2_CLIFOR"  , AvKey("","PC2_CLIFOR"))
	oModel:LoadValue("MASTER","PC2_LOJA"    , AvKey("","PC2_LOJA"))
	oModel:LoadValue("MASTER","PC2_NMCLFR"  , AvKey("","PC2_NMCLFR"))

	Restarea(AreaAtu)

Return(lOk)


//Acrescentar Zeros a Esquerda (Nota Fiscal)
User Function F04045NT(cNotaFiscal)
/*
+==============================================================================+
| Programa: Acrescentar Zeros a Esquerda (Nota Fiscal)                         |  															   |
| Autor   : André Francisco                                                    |
| Data    : 13/08/2021                                                         |
| Chamado : 108127                                                             |
| Ticket  : ---                                                                |
| Versão  : 1.00   															   |
| Return  : True                                                               |
+==============================================================================+
| Especificação: Ajuste na tela de registro de pesagem para que os             |
|                dois campos NOTA FISCAL e SERIE, os mesmo tem que             |
|                ser NOTA com 9 dígitos e SERIE 3 dígitos, preciso que         |
|                reconheça com zeros anterior ao numero, de forma automático,  | 
|                ex: 232 preencher 000000232.                                  |
+==============================================================================+
*/
Local oModel    := FWModelActive()
Local nTamanho := TamSX3('PC2_NOTA')[01]

	If !Empty(cNotaFiscal)
         cNotaFiscal  := PadL(Alltrim(cNotaFiscal), nTamanho, '0')
    EndIf
 
 oModel:LoadValue("MASTER","PC2_NOTA", cNotaFiscal)

Return .T.

//Acrescentar Zeros a Esquerda (Série)
User Function F04045SE(cSerie)
/*
+==============================================================================+
| Programa: Acrescentar Zeros a Esquerda (Série)                               |  															   |
| Autor   : André Francisco                                                    |
| Data    : 13/08/2021                                                         |
| Chamado : 108127                                                             |
| Ticket  : ---                                                                |
| Versão  : 1.00   															   |
| Return  : True                                                               |
+==============================================================================+
| Especificação: Ajuste na tela de registro de pesagem para que os             |
|                dois campos NOTA FISCAL e SERIE, os mesmo tem que             |
|                ser NOTA com 9 dígitos e SERIE 3 dígitos, preciso que         |
|                reconheça com zeros anterior ao numero, de forma automático,  | 
|                ex: 232 preencher 000000232.                                  |
+==============================================================================+
*/
Local oModel    := FWModelActive()
Local nTamanho := TamSX3('PC2_SERIE')[01]

	If !Empty(M->PC2_SERIE) .Or. !Empty(cSerie)
         cSerie  := PadL(Alltrim(cSerie), nTamanho, '0')
    EndIf

 oModel:LoadValue("MASTER","PC2_SERIE", cSerie)

Return .T.


//Habilita e desabilita as teclas de Atalho
User Function F04045KEY(oModel,lAtiva)

	If lAtiva
		SetKey( VK_F8	, { || U_F0404541( oModel , "VIEW" , M->PC2_CTRLE, M->PC2_OPERA, M->PC2_TIPMOV , oModel:GetOperation(), cFilAnt,M->PC2_NFENTR, M->PC2_STATUS ) } )
		SetKey( VK_F9	, { || U_F0404501(oModel) } )
		SetKey( VK_F10	, { || U_F0404544(oModel) } )
		SetKey( VK_F11	, { || U_F0404560(oModel) } )
		SetKey( VK_F12	, { || U_F0404561(oModel) } )
	Else
		SetKey( VK_F8	, { ||  } )
		SetKey( VK_F9	, { ||  } )
		SetKey( VK_F10	, { ||  } )
		SetKey( VK_F11	, { ||  } )
		SetKey( VK_F12	, { ||  } )
	EndIf

Return

//Procura o proximo seguencial disponivel
User Function F04045COD()

	Local cCodRet  	:= GetSxeNum("PC2","PC2_CTRLE")
	Local aAreaAtu 	:= getarea()

	While .t.

		dbSelectArea("PC2")
		dbSetorder(1)
		If dbseek(cFilAnt+cCodRet)
			ConFirmSX8()
			cCodRet := GetSxeNum("PC2","PC2_CTRLE")
		Else
			exit
		EndIf

	End

	Restarea(aAreaAtu)

Return(cCodRet)


/*/{Protheus.doc} LocDK0

Localiza a DK0 (viagem) a partir do id da viagem

@type function
@version
@author fabio.cazarini
@since 24/06/2020
@return return_type, return_description
/*/
Static Function LocDK0(cViagem)
    Local lRet      := .F.
    Local cQuery    := ""
    Local cAliasQry := ""

    If Empty(cViagem)
        Return .F.
    EndIf

    cQuery := "SELECT DK0.R_E_C_N_O_ RECNODK0"
    cQuery += "  FROM " + RetSqlName("DK0") + " DK0 "
    cQuery += " WHERE DK0.DK0_FILIAL = '" + FwXFilial("DK0") + "' "
    cQuery += "   AND DK0.DK0_VIAGID = '" + cViagem + "' "
    cQuery += "   AND DK0.D_E_L_E_T_ = ' ' "

    cQuery      := ChangeQuery(cQuery)
    cAliasQry   := MPSysOpenQuery(cQuery)

    (cAliasQry)->( DbGoTop() )
    If (cAliasQry)->( !EoF() )
        lRet := .T.
        DK0->( DbGoTo( (cAliasQry)->RECNODK0 ) )
    Endif
    (cAliasQry)->( DbCloseArea() )

Return lRet
