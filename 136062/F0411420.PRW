#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "TopConn.ch"

//Variáveis Estáticas
Static cTitulo := "Integrações AGPR5 - Retorno do AGPR5"

//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0411420

Tabela Intermediária - Retorno AGPR5

@author  Ronaldo Dantas
@since 15/01/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0411420()

	Local aArea   := GetArea()
	Local oMark
	Local lMarcar      := .F.

	oMark := FWMarkBrowse():New()
	oMark:setmenudef("F0411420")

	oMark:AddLegend("PD9_STATUS == '0' ",	"BLUE"		, "Recebida")
	oMark:AddLegend("PD9_STATUS == '1' ",	"YELLOW"	, "Em processamento")
	oMark:AddLegend("PD9_STATUS == '2' ",	"GREEN"		, "Processada com Sucesso")
	oMark:AddLegend("PD9_STATUS == '9' ",	"RED"		, "Falha no processamento")

	oMark:SetAlias("PD9")
	oMark:SetDescription(cTitulo)

	 //Setando semáforo, descrição e campo de mark
    oMark:SetSemaphore(.F.)
    oMark:SetDescription("Seleção da batelada")
    oMark:SetFieldMark("PD9_OK")  // Criação do Campo no Banco de Dados "PD9_OK"

	//Indica o Code-Block executado no clique do header da coluna de marca/desmarca
	oMark:bAllMark := { || MCFG6Invert(oMark:Mark(),lMarcar := !lMarcar ), oMark:Refresh(.T.)  }

	oMark:Activate()

	RestArea(aArea)

Return Nil


//-----------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
//Criação de Menu MVC
@author Ronaldo Dantas
@since 15/01/2021
@return aRotina

@type function
/*/
//-----------------------------------------------------------------------------
Static Function MenuDef()

	Local aRot := {}

	//Adicionando opções
	ADD OPTION aRot TITLE 'Visualizar' 			ACTION 'VIEWDEF.F0411420' 	OPERATION MODEL_OPERATION_VIEW   	ACCESS 0
	ADD OPTION aRot TITLE 'Alterar' 			ACTION 'U_F0411421' 		OPERATION MODEL_OPERATION_UPDATE 	ACCESS 0
	ADD OPTION aRot TITLE 'Reprocessar' 		ACTION 'U_F0411422' 		OPERATION MODEL_OPERATION_UPDATE 	ACCESS 0
	ADD OPTION aRot TITLE 'Cancelar' 			ACTION 'U_F0411423' 		OPERATION MODEL_OPERATION_UPDATE 	ACCESS 0
	ADD OPTION aRot TITLE 'Processar Recebidas'	ACTION 'U_F0411424' 		OPERATION MODEL_OPERATION_UPDATE 	ACCESS 0
	ADD OPTION aRot TITLE 'Contar'				ACTION 'U_F0411425' 		OPERATION MODEL_OPERATION_VIEW 		ACCESS 0

Return aRot


//-----------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
//Criação do modelo de dados MVC
@author Ronaldo Dantas
@since 15/01/2021
@return oModel
@type function
/*/
//-----------------------------------------------------------------------------
Static Function ModelDef()

	Local oModel 	:= Nil
	Local oStPai 	:= FWFormStruct(1, 'PD9')
	Local oStFilho 	:= FWFormStruct(1, 'PDA')
	Local bLinePre  := {|oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue| linePreGrid(oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue)}

	oStPai:SetProperty('PD9_LOTEN'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_STATUS'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_CODFOR'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_DTINFM'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_DTFNFM'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_FILAVE'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_HRINI'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_HRFIM'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_NUMBAT'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_QTDPRO'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_DTPROC'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_HRPROC'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_DATA'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_HORA'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_RETORN'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_SERVIC'		, MODEL_FIELD_WHEN,{|| .F. })
	oStPai:SetProperty('PD9_ID'			, MODEL_FIELD_WHEN,{|| .F. })

	oStFilho:SetProperty('PDA_FILAVE'	, MODEL_FIELD_WHEN,{|| .F. })
	oStFilho:SetProperty('PDA_LOTEN'	, MODEL_FIELD_WHEN,{|| .F. })
	oStFilho:SetProperty('PDA_ITEM'		, MODEL_FIELD_WHEN,{|| .F. })
	oStFilho:SetProperty('PDA_COD'		, MODEL_FIELD_WHEN,{|| .F. })
	oStFilho:SetProperty('PDA_QTD'		, MODEL_FIELD_WHEN,{|| .F. })
	oStFilho:SetProperty('PDA_DTINT'	, MODEL_FIELD_WHEN,{|| .F. })
	oStFilho:SetProperty('PDA_STATUS'	, MODEL_FIELD_WHEN,{|| .F. })
	oStFilho:SetProperty('PDA_RETORN'	, MODEL_FIELD_WHEN,{|| .F. })

	//Criando o modelo e os relacionamentos
	oModel := MPFormModel():New('MF0411420',/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/)

	oModel:AddFields('PD9MASTER',/*cOwner*/,oStPai)

	oModel:AddGrid('PDADETAIL','PD9MASTER',oStFilho,bLinePre, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)  //cOwner é para quem pertence

	oModel:SetRelation('PDADETAIL',{{"PDA_FILAVE",'PD9_FILAVE'},{"PDA_NUMBAT","PD9_NUMBAT"}}, PDA->( IndexKey( 1 ) )  )

	oModel:SetPrimaryKey({'PD9_FILAVE','PD9_NUMBAT'})

	oModel:SetDescription(cTitulo)

Return oModel


//-----------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
//Criação de VIEW MVC
@author Ronaldo Dantas
@since 15/01/2021
@return aRotina

@type function
/*/
//-----------------------------------------------------------------------------
Static Function ViewDef()

	Local oView		:= Nil
	Local oModel	:= FWLoadModel('F0411420')
	Local oStPai	:= FWFormStruct(2, 'PD9')
	Local oStFilho	:= FWFormStruct(2, 'PDA')

	oStFilho:RemoveField( "PDA_NUMBAT" )

	//Criando a View
	oView := FWFormView():New()
	oView:SetModel(oModel)

	//Adicionando os campos do cabeçalho e o grid dos filhos
	oView:AddField('VIEW_PD9',oStPai,'PD9MASTER')
	oView:AddGrid('VIEW_PDA',oStFilho,'PDADETAIL')

	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',40)
	oView:CreateHorizontalBox('GRID',60)

	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_PD9','CABEC')
	oView:SetOwnerView('VIEW_PDA','GRID')

	//Habilitando título
	oView:EnableTitleView('VIEW_PD9','Integracoes AGPR5 - Retorno AGPR5')
	oView:EnableTitleView('VIEW_PDA','Itens')

Return oView


//-----------------------------------------------------------------------------
/*/{Protheus.doc} linePreGrid
//Nao permitir deletar itens
@author Ronaldo Dantas
@since 15/01/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
Static Function linePreGrid(oGridModel, nLine, cAction, cIDField, xValue, xCurrentValue)
	Local lRet := .T.

	If cAction == "DELETE"
		lRet := .F.
		oGridModel:GetModel():SetErrorMessage('PDADETAIL', NIL , 'PDADETAIL' , NIL , 'Erro', 'Não é possível excluir linhas', '')
	EndIf

Return lRet


//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0411421
//Altera
@author Ronaldo Dantas
@since 15/01/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0411421()
	Local xRet := NIL

	If PD9->PD9_STATUS == "9" // 0=Recebida;1=Em processamento;2=Processada com Sucesso;9=Falha no processamento
		xRet := FWExecView( cTitulo, "F0411420", MODEL_OPERATION_UPDATE,, {|| .T.})	//"Alteração"
	else
		Help( ,, "HELP",, "Somente integrações com falha de processamento podem ser alteradas.", 1, 0)
	Endif

Return xRet


//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0411422
//Reprocessar
@author Ronaldo Dantas
@since 15/01/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0411422()

	Local lPosicionada 	:= .T.
	Local aAreaPD9		:= PD9->( GetArea() )
	Local aDados 		:= {}
	Local cAlias		:= GetNextAlias()
	Local cAlias2		:= GetNextAlias()
	Local cMarca 		:= oMark:Mark()
	//Local lInverte 		:= oMark:IsInvert()
	Local i
	Local n 			:= 0
	Local cOk
	Local cnOk
	local oDlg := nil, oEdit := nil

	
	//Validar se foi selecionado algum registro
	dbSelectArea("PD9")
	cQuery 		:= " SELECT PD9.PD9_FILAVE, PD9.PD9_STATUS, PD9.PD9_NUMBAT, "	+ CRLF
	cQuery 		+=	"PD9.PD9_DTPROC ,PD9.PD9_OK, PD9.R_E_C_N_O_	" 				+ CRLF
	cQuery 		+= " FROM " + RetSQLName("PD9") + " PD9  "						+ CRLF
	cQuery 		+= " WHERE PD9.D_E_L_E_T_ = ' ' " 								+ CRLF
	cQuery 		+= " AND PD9.PD9_OK = '" + cMarca + "' "						+ CRLF

	TCQUERY cQuery NEW ALIAS (cAlias)
    (cAlias)->(DbGoTop())

	 If Empty((cAlias)->PD9_OK)
	     Alert("Nenhuma Batelada Selecionada!")
        return
    Endif

		Do While !(cAlias)->(Eof())

	 	//Validar se ja existe batelada processada 
		dbSelectArea("SH6")
		cQuery 		:= " SELECT * FROM " + RetSQLName("SH6")+ " SH6"      + CRLF 
		cQuery 		+= " WHERE SH6.D_E_L_E_T_ = ' ' " 			     	  + CRLF
		cQuery 		+= " AND SH6.H6_XNUMBAT = '" + PD9->PD9_NUMBAT + "'	" + CRLF
	
		TCQUERY cQuery NEW ALIAS (cAlias2)

		if !(cAlias2)->(Eof())
			lRet := .F.
		endif 

		if lRet
				aAdd(aDados,{;
							(cAlias)->PD9_FILAVE,;
							(cAlias)->PD9_STATUS,;
							(cAlias)->PD9_NUMBAT,;
							(cAlias)->PD9_DTPROC;
							})
		elseif PD9->PD9_STATUS $ "0|9"
			dbSelectArea("PD9")
			PD9->(DbGoTo((cAlias)->R_E_C_N_O_))
                    Reclock("PD9",.F.)
                    PD9->PD9_STATUS := '2'
                    MsUnlock()		
		else 
			aAdd(aDados,{;
							(cAlias)->PD9_FILAVE,;
							(cAlias)->PD9_STATUS,;
							(cAlias)->PD9_NUMBAT,;
							(cAlias)->PD9_DTPROC;
							})		
		endif
			cAlias2	:= GetNextAlias()
			(cAlias)->(DbSkip())
		EndDo

    if Empty(aDados)
        return
    Endif

	For i := 1 to Len(aDados)
				If aDados[i,2] $ "0|9"
					If Empty(cOk)
						cOk  := aDados[i,3]
					Elseif n == 6
						cOk  += CRLF + aDados[i,3]
						n := 0
					else
						cOk  += "," + aDados[i,3]
					EndIf
					n +=1
				Else
					If Empty(cnOk)
						cnOk  := aDados[i,3]
					Else
						cnOk  += ", " + aDados[i,3]
					EndIf
				EndIf
	Next i

	If !Empty(cnOk)
		DEFINE DIALOG oDlg TITLE "Restrições no reprocessamento!!" FROM 180, 180 TO 550, 700 PIXEL
		oEdit := tSimpleEditor():New(0, 0, oDlg, 263, 186)
		oEdit:Load("<font size=5> Somente integrações com o status de </font>" +;
			"<font size=5>'0-Recebida' ou '9-Falha de processamento' </font>" +;
			"<font size=5>, podem ser reprocessadas! </font> <br> <br> <br>" +;
			"<font size=5> As Bateladas: </font> <br> <br>" +;
			"<font size=5><b> " + cValToChar(cnOk) + "</b></font> <br> <br>"+;
			"<font size=5> Não podem ser reprocessadas! </font>")
		@ 162,219 BUTTON "Continuar" SIZE 040, 020 PIXEL OF oDlg ACTION (nOpca := 1, oDlg:End())
		ACTIVATE DIALOG oDlg CENTERED
	EndIf

	if !Empty(cOk)
		If MSGNOYES("Integrações Selecionadas: " + cValToChar(cOk) + " " + CRLF + CRLF + "Deseja realmente reprocessar a integração?")
			For i := 1 to Len(aDados)

				If aDados[i,2] $ "0|9" // se estiver com falha de processamento	
						aAreaPD9	:= PD9->( GetArea() )

						    DbSelectArea("PD9")
							PD9->( DbSetOrder(1) ) // PD9_FILAVE+PD9_NUMBAT
							PD9->( MsSeek( aDados[i,1] + aDados[i,3]) )

						FWMsgRun(, {|| U_J0411420({FwCodEmp(), FwCodFil()}, aDados[i,3], lPosicionada)}, "Requisicoes AGPR5","Reprocessando...")	
						RestArea( aAreaPD9 ) 
				Endif
				
			Next i
		Endif
		//RestArea( aAreaPD9 ) 
	EndIf

Return NIL


//-----------------------------------------------------------------------------
/*/{Protheus.doc} Função para marcar/desmarcar todos os registros do grid
//Cancelar
@author 
@since 01/02/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
Static Function MCFG6Invert(cMarca,lMarcar)
    Local cAliasPD9 := 'PD9'
    Local aAreaPD9  := (cAliasPD9)->( GetArea() )
    dbSelectArea(cAliasPD9)
    (cAliasPD9)->( dbGoTop() )
    While !(cAliasPD9)->( Eof() )
        RecLock( (cAliasPD9), .F. )
        (cAliasPD9)->PD9_OK := IIf( lMarcar, cMarca, '  ' )
        MsUnlock()
        (cAliasPD9)->( dbSkip() )
    EndDo
    RestArea( aAreaPD9 )
Return .T.



//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0411423
//Cancelar
@author 
@since 01/02/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0411423()

	Local aAreaPD9	:= PD9->( GetArea() )
	Local cHrIni	:= PD9->PD9_HORA
	Local cHrFim 	:= Time()
	Local cHrSoma	:= ""	

	// se 1-Em processamento
	If PD9->PD9_STATUS $ "1"
		//Calcula o tempo desde a hora da integração
		cHrSoma := ElapTime(cHrIni,cHrFim)
		//Se for maior ou igual a 10 minutos muda o status para reprocessar
		If cHrSoma >= '00:10:00' .Or. PD9->PD9_DATA <> Date()
			If MSGNOYES("Integração posicionada - Data: " + DTOC(PD9->PD9_DTPROC) + " - Status: " + PD9->PD9_STATUS + CRLF + CRLF + "Deseja realmente CANCELAR o processamento?")
				RecLock("PD9", .F.) 
					PD9->PD9_STATUS   := "9" // Falha no processamento
					PD9->PD9_RETORN	  := 'ERRO| Excedeu o tempo na execução'
					PD9->PD9_DTPROC	  := Date()
					PD9->PD9_HRPROC   := Time()
				PD9->( MsUnLock() )   	
			Endif
		Else
			Help( ,, "HELP",, "É necessário aguardar 10 minutos após o recebimento para cancelar o processamento. Tempo decorrido: " + cHrSoma, 1, 0)   			
		EndIf			
	else
		Help( ,, "HELP",, "Somente integrações no status 1-Em Processamento podem ser cancelada.", 1, 0)   
	Endif

	RestArea( aAreaPD9 ) 

Return NIL


//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0411424

Processar todos recebidos

@author Fábio Cazarini
@since 02/02/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0411424()

	If MSGNOYES("Deseja realmente PROCESSAR TODAS as integrações RECEBIDAS?" + CRLF + CRLF + "O processo será executado em segundo plano...")
		StartJob("U_J0411420", GetEnvServer(), .F., {FwCodEmp(), FwCodFil()})
	Endif

Return NIL


//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0411425

Contar recebidos e em processamento

@author Fábio Cazarini
@since 03/02/2021
@return NIL
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0411425()

    Local cQuery    := ""
    Local cAliasQry := ""
	Local nSt0		:= 0
	Local nSt1		:= 0
	Local cMsgAviso	:= ""

    cQuery := " SELECT PD9.PD9_STATUS, Count(*) CNT "
    cQuery += " FROM " + RetSqlName("PD9") + " PD9 "
    cQuery += " WHERE PD9.PD9_FILIAL = '" + xFilial("PD9") + "' " 
    cQuery += "     AND PD9.PD9_STATUS IN ('0','1') "
    cQuery += "     AND PD9.D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY PD9.PD9_STATUS "

    cQuery      := ChangeQuery(cQuery)
    cAliasQry   := MPSysOpenQuery(cQuery)

    Do While (cAliasQry)->( !Eof() )
		If (cAliasQry)->PD9_STATUS == "0"
			nSt0 := (cAliasQry)->CNT
		Endif	
		If (cAliasQry)->PD9_STATUS == "1"
			nSt1 := (cAliasQry)->CNT
		Endif	

        (cAliasQry)->( DbSkip() )
    Enddo

    (cAliasQry)->( DbCloseArea() )

	cMsgAviso += "Status 0-Recebida: " + Alltrim(Str(nSt0)) + CRLF + CRLF
	cMsgAviso += "Status 1-Em Processamento: " + Alltrim(Str(nSt1)) + CRLF + CRLF

	Aviso("Status da integração", cMsgAviso, {"Fechar"}, 2)

Return NIL
