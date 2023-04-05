// -------------------------------------------------------------------------------------------
// Projeto: GTFoods
// Fonte  : F0404563
// ---------+---------------------+-----------------------------------------------------------
// Data     | Autor			  	  | Descrição
// ---------+---------------------+-----------------------------------------------------------
// 29/01/20 | Ricardo Mendes  	  | Rotina de Gerar várias notas de entrada referente Lorenz
// ---------+---------------------+-----------------------------------------------------------
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'

User Function F0404563(nOpcAuto)
	Local lNotaLanc	:= .F.
	Local lNotaFinc	:= .F.		

	//Função para validar se alguma nota já está lançada
	lNotaLanc := PesqSF1(PC2->PC2_CTRLE)
	nOpcAuto := 3

	IF lNotaLanc
		Return .F.
	Else
		lNotaFinc := PesqSA2(PC2->PC2_CTRLE)
		IF lNotaFinc			
			Return .F.
		Else
			TelaProc(nOpcAuto)
		EndIF
	EndIF

Return .T.

//Função para processar geração da Nota
Static Function GeraNF(nOpcAuto)
	Local aAreaAtu 		:= getarea()
	Local aAreaPC2 		:= PC2->(getarea())
	Local aAreaPAE 		:= PAE->(getarea())
	Local cF1_DOC		:= ""
	Local cF1_SERIE		:= ""
	Local cF1_FORNECE	:= ""
	Local cF1_LOJA		:= ""
	Local cF1_FORMUL	:= "N"
	Local nD1_QUANT		:= 0
	Local nD1_VUNIT		:= 0
	Local nD1_TOTAL		:= 0
	Local nD1_VALFRE	:= 0
	Local aLinha		:= {}
	Local aItens		:= {}
	Local aCabec		:= {}
	Local cMsgOK		:= ""

	Local cNFPSerie		:= SuperGetMV("FS_C04045H",, "001")	//Serie da Nota de transmissão para Entrada de Mandioca (SPED)
	Local cTESNFP		:= SuperGetMV("FS_C04045I",, "007")	//TES da Nota de Transmissão para Entrada de Mandioca (SPED)
	Local cMPdrNFP		:= SuperGetMV("FS_C04045J",, "")	//Mensagem padrão de Transmissão para Entrada da Madioca(SPED)
	Local cTpFrNFP		:= SuperGetMV("FS_C04045K",, "S")	//Tipo de Frete de Transmissão para Entrada da Madioca(SPED)
	Local cTESNor		:= SuperGetMV("FS_C04045L",, "075")	//TES da Nota de Transmissão para Entrada de Mandioca (NFP)
	Local cMPdrNor		:= SuperGetMV("FS_C04045M",, "")	//Mensagem padrão de Transmissão para Entrada da Madioca(NFP)
	Local cTpFrNor		:= SuperGetMV("FS_C04045N",, "S")	//Tipo de Frete de Transmissão para Entrada da Madioca(NFP)
	Local cCndPgto		:= SuperGetMV("FS_C04045O",, "006")	//Condição de Pagamento para Entrada de Mandioca
	Local cMsgNFP		:= ""
	Local cMsgNor		:= ""
	Local cOrigem		:= ""
	Local cClasTes  	:= ""
	Local lGeraNFP		:= .F.
	Local cItOri        := "0001"
	Local cHorEst       := FwTimeUF(SM0->M0_ESTENT)[2]


	oLstProc:Reset()
	oBtnGerar:Disable()
	oBtnSair:Disable()
	AddList("Iniciando Processo de Nota Fiscal de Entrada")

	dbSelectArea("PAE")
	PAE->(dbsetOrder(1))
	If PAE->(dbSeek(xFilial("PAE")+PC2->PC2_CTRLE))
		lProcOK := .T.
		While PAE->(!eof() .and. PAE->PAE_FILIAL == xFilial("PAE") .AND. PAE->PAE_CTRLE == PC2->PC2_CTRLE)
			aItens 		:= {}
			aCabec		:= {}

			lGeraNFP	:= IIF(PC2->PC2_NFP == "S",.T.,.F.)

			cF1_FORMUL  := "N" //IIF(PC2->PC2_NFP == "S","N","N") comentado para gerar a Tag refNFP corretamente
			cF1_DOC     := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_NFPROD,PC2->PC2_NOTA)
			cF1_SERIE   := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_SERPRO,PC2->PC2_SERIE)
			cF1_FORNECE := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_PRODUT,PC2->PC2_CLIFOR)
			cF1_LOJA    := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_LOJA  ,PC2->PC2_LOJA)

			SA2->(dbSeek(xFilial("SA2")+cF1_FORNECE+cF1_LOJA))//Validação da TES por estado do produtor
			cEstado 	:= SA2->A2_EST
			cTESNFP		:= (subs(cTESNFP,at(cEstado,cTESNFP)+2,3))

			nD1_QUANT	:= A410Arred(IIF(PAE->PAE_PERPRD != 100,PAE->PAE_PESPRD,PC2->PC2_PESLIQ) , 'D1_QUANT')
			nD1_VUNIT	:= A410Arred(PAE->PAE_UNIKG , 'D1_VUNIT')
			nD1_TOTAL	:= A410Arred(nD1_QUANT * nD1_VUNIT , 'D1_TOTAL')
			nD1_VALFRE 	:= PAE->PAE_VLRFRE

			IF !Empty(cF1_DOC)
				cF1_DOC := StrZero(Val(cF1_DOC),9)
			EndIF

			aLinha := {}
			aadd(aLinha,{"D1_DOC"		, cF1_DOC														,Nil})
			aadd(aLinha,{"D1_SERIE"		, cF1_SERIE														,Nil})
			aadd(aLinha,{"D1_COD"		, PAE->PAE_PROD													,Nil})
			aadd(aLinha,{"D1_DESCRI"	, PAE->PAE_NMPRD												,Nil})										 
			aadd(aLinha,{"D1_QUANT"		, nD1_QUANT														,NIL})
			aadd(aLinha,{"D1_VUNIT"		, nD1_VUNIT														,Nil})
			aadd(aLinha,{"D1_XCODPES"	, PC2->PC2_CTRLE												,Nil})
			aadd(aLinha,{"D1_ITEMCTA"	, PC2->PC2_ITEMCT												,Nil})
			aadd(aLinha,{"D1_CC"		, PC2->PC2_CENTRO												,Nil})
			aadd(aLinha,{"D1_PESO"		, PC2->PC2_PESPLT												,Nil})
			aadd(aLinha,{"D1_VALFRE"	, nD1_VALFRE													,Nil})
			aadd(aLinha,{"D1_TOTAL"		, nD1_TOTAL      												,Nil})
			aadd(aLinha,{"D1_OP"		, ""															,Nil})

			IF lGeraNFP
				cOrigem		:= Left(posicione("SB1",1,FwXFilial("SF1")+PAE->PAE_PROD	,"B1_ORIGEM")	,1)
				cClasTes	:= Left(posicione("SF4",1,FwXFilial("SF4")+cTESNor			,"F4_SITTRIB")	,2)

				aadd(aLinha, {"D1_TES"    	, cTESNor       											,Nil})
				aadd(aLinha, {"D1_CLASFIS"	, cOrigem+cClasTes  										,Nil})
				aadd(aLinha, {"D1_DTDIGIT"	, dDataBase      											,Nil})
			EndIF	

			AAdd(aItens, aLinha)
			aItens := FWVetByDic( aItens, "SD1", .T. )

			aadd(aCabec, {"F1_FILIAL"	, FwXFilial("SF1") 												,NIL})
			aadd(aCabec, {"F1_TIPO"		, "N"		                      								,NIL})
			aadd(aCabec, {"F1_FORMUL"	, "N"		                   									,NIL})
			aadd(aCabec, {"F1_DOC"		, cF1_DOC                       								,NIL})
			aadd(aCabec, {"F1_SERIE"	, cF1_SERIE                     								,NIL})
			aadd(aCabec, {"F1_FORNECE"	, cF1_FORNECE                   								,NIL})
			aadd(aCabec, {"F1_LOJA"		, cF1_LOJA                      								,NIL})
			aadd(aCabec, {"F1_EMISSAO"	, PC2->PC2_DTEMIS               								,NIL})
			aadd(aCabec, {"F1_ESPECIE"	, PC2->PC2_ESPECI               								,NIL})
			aadd(aCabec, {"F1_XNOME"	, IIF(PAE->PAE_PERPRD != 100,PAE->PAE_NMPROD,PC2->PC2_NMCLFR)	,NIL})
			aadd(aCabec, {"F1_FRETE"	, nD1_VALFRE                    								,NIL})
			aadd(aCabec, {"F1_COND"		, cCndPgto														,NIL})
			aadd(aCabec, {"F1_TRANSP" 	, PC2->PC2_TRANSP            									,NIL})
			aadd(aCabec, {"F1_PLACA"  	, PC2->PC2_PLACA           										,NIL})

			IF lGeraNFP
				cMsgNor		:= "COMPRA DE RAIZ DE MANDIOCA-NFP "
				aadd(aCabec,{"F1_MENPAD" 	, cMPdrNor             										,NIL})
				aadd(aCabec,{"F1_MENNOTA"	, cMsgNor                   								,NIL})
				aadd(aCabec,{"F1_TPFRETE"	, cTpFrNor		  		  									,NIL}) 
				aadd(aCabec,{"F1_HORA"   	, cHorEst                   								,NIL})
				aadd(aCabec,{"F1_VOLUME1"	, nD1_QUANT													,NIL})
				aadd(aCabec,{"F1_PLIQUI"	, nD1_QUANT													,NIL})
				aadd(aCabec,{"F1_PBRUTO"	, nD1_QUANT													,NIL})
				aadd(aCabec,{"F1_ESPECI1"	,"DIVERSOS"													,NIL})

			EndIF

			aCabec := FWVetByDic( aCabec, "SF1" )

			//Chamar Rotina de Criação da Nota
			IF CriaNota(aCabec, aItens, IIF(lGeraNFP,"N","P") )
				aCabec		:= {}
				aLinha		:= {}
				aItens		:= {}

				IF lGeraNFP
					//cNFPDocum	:= MA461NumNf(.T.,cNFPSerie)
					cMsgNFP		:= "REF. NFP Nota:"+Alltrim(cF1_DOC)+" Serie: "+Alltrim(cF1_SERIE)+" Filial: "+FwXFilial("SF1")

					aLinha := {}
					aadd(aLinha, {"D1_COD"		, PAE->PAE_PROD													,Nil})
					aadd(aLinha, {"D1_DESCRI"	, PAE->PAE_NMPRD												,Nil})										 
					aadd(aLinha, {"D1_QUANT"	, nD1_QUANT														,NIL})
					aadd(aLinha, {"D1_VUNIT"	, nD1_VUNIT														,Nil})
					aadd(aLinha, {"D1_XCODPES"	, PC2->PC2_CTRLE												,Nil})
					aadd(aLinha, {"D1_ITEMCTA"	, PC2->PC2_ITEMCT												,Nil})
					aadd(aLinha, {"D1_CC"		, PC2->PC2_CENTRO												,Nil})
					aadd(aLinha, {"D1_PESO"		, PC2->PC2_PESPLT												,Nil})
					aadd(aLinha, {"D1_VALFRE"	, nD1_VALFRE													,Nil})
					aadd(aLinha, {"D1_TOTAL"	, nD1_TOTAL      												,Nil})
					aadd(aLinha, {"D1_OP"		, ""															,Nil})
					aadd(aLinha, {"D1_TES"    	, cTESNFP   											    	,Nil})
					aadd(aLinha, {"D1_DTDIGIT"	, dDataBase      												,Nil})
					aadd(aLinha, {"D1_NFORI" 	, cF1_DOC														,Nil}) // nota de origem
					aadd(aLinha, {"D1_SERIORI"	, cF1_SERIE														,Nil}) // serie de origem
					aadd(aLinha, {"D1_ITEMORI"	, cItOri 															,Nil}) // Item de origem
					aadd(aLinha, {"D1_DATORI"	, PC2->PC2_DTEMIS 												,Nil}) // Data de origem 

					AAdd(aItens, aLinha)
					aItens := FWVetByDic( aItens, "SD1", .T. )


					aadd(aCabec, {"F1_FILIAL"	, FwXFilial("SF1") 												,NIL})
					aadd(aCabec, {"F1_TIPO"		, "N"		                      								,NIL})
					aadd(aCabec, {"F1_FORMUL"	, "S"		                   									,NIL})
					aadd(aCabec, {"F1_DOC"		, CriaVar("F1_DOC",.F.)/*cNFPDocum*/  							,NIL})
					aadd(aCabec, {"F1_SERIE"	, cNFPSerie                    									,NIL})
					aadd(aCabec, {"F1_FORNECE"	, cF1_FORNECE                   								,NIL})
					aadd(aCabec, {"F1_LOJA"		, cF1_LOJA                      								,NIL})
					aadd(aCabec, {"F1_EMISSAO"	, dDataBase			               								,NIL})
					aadd(aCabec, {"F1_ESPECIE"	, "SPED"			               								,NIL})
					aadd(aCabec, {"F1_XNOME"	, IIF(PAE->PAE_PERPRD != 100,PAE->PAE_NMPROD,PC2->PC2_NMCLFR)	,NIL})
					aadd(aCabec, {"F1_FRETE"	, nD1_VALFRE                    								,NIL})
					aadd(aCabec, {"F1_COND"		, cCndPgto														,NIL})
					aadd(aCabec, {"F1_TRANSP" 	, PC2->PC2_TRANSP            									,NIL})
					aadd(aCabec, {"F1_PLACA"  	, PC2->PC2_PLACA           										,NIL})
					aadd(aCabec, {"F1_MENPAD" 	, cMPdrNFP             											,NIL})
					aadd(aCabec, {"F1_MENNOTA"	, cMsgNFP                   									,NIL})
					aadd(aCabec, {"F1_TPFRETE"	, cTpFrNFP		  		  										,NIL}) 
					aadd(aCabec, {"F1_HORA"   	, cHorEst             									        ,NIL})
					aadd(aCabec, {"F1_VOLUME1"	, nD1_QUANT														,NIL})
					aadd(aCabec, {"F1_PLIQUI"	, nD1_QUANT														,NIL})
					aadd(aCabec, {"F1_PBRUTO"	, nD1_QUANT														,NIL})
					aadd(aCabec, {"F1_ESPECI1"	,"DIVERSOS"														,NIL})

					aCabec := FWVetByDic( aCabec, "SF1" )

					//Chamar Rotina de Criação da Nota
					IF !CriaNota(aCabec, aItens, "S" )
						cMsgOK := "Erro"
						Exit
					EndIF

				EndIF
			Else
				cMsgOK := "Erro"
				Exit
			EndIF
			PAE->(dbSkip())
		EndDo

		If Empty(cMsgOK)// So exibo se houve sucesso na operacao
			PC2->(RecLock("PC2",.F.))
			PC2->PC2_DATCLS := dDataBase
			PC2->PC2_USRCLS := RetCodUsr()
			PC2->PC2_HORCLS := Left(time(),5)
			PC2->PC2_STATUS := "C"
			PC2->(MsUnlock())

			//Integração com o GAP 078 - Painel de Faturamento
			IF PC2->PC2_STATUS == "C"
				U_G0507813(PC2->PC2_CTRLE)
			EndIF

			FwMsgRun(,{|| U_F0202201()},"Envio Pesagem","P04045")
		EndIf

		lProcOK := .F.
		oBtnSair:Enable()
		AddList("Processo Finalizado")

	EndIf

	RestArea(aAreaPAE)
	RestArea(aAreaPC2)
	RestArea(aAreaAtu)

Return .T.

//Tela de Processamento
Static Function TelaProc(nOpcAuto)
	Private lProcOK			:= .F.

	SetPrvt("oJanMand","oBtnSair","oGrpProc","oBtnGerar","oPnlInfer","oLstProc" )

	oJanMand   := MSDialog():New( 092,232,538,845," Processamento de Compra de Mandioca ",,,.F.,,,,,,.T.,,,.T. )

	oPnlInfer  := TPanel():New( 100,004,"",oJanMand,,.F.,.F.,,,164,016,.T.,.F. )
	oPnlInfer:align:= CONTROL_ALIGN_BOTTOM

	oBtnSair	:= TButton():New( 199,008,"&Fechar",oPnlInfer,{|| VldSaid() },(oPnlInfer:nWidth/2)-15,016,,,,.T.,,"",,,,.F. )
	oBtnSair:align:= CONTROL_ALIGN_RIGHT
	oBtnSair:Disable()

	oBtnGerar	:= TButton():New( 199,008,"&Gerar NF",oPnlInfer,{|| GeraNF() },(oPnlInfer:nWidth/2)-15,016,,,,.T.,,"",,,,.F. )
	oBtnGerar:align:= CONTROL_ALIGN_LEFT

	oGrpProc	:= TGroup():New( 000,001,199,300," Listagem de Processamento ",oJanMand,CLR_BLACK,CLR_WHITE,.T.,.F. )
	oGrpProc:align:= CONTROL_ALIGN_ALLCLIENT 

	oLstProc	:= TListBox():New( 104,008,,,316,116,,oGrpProc,,CLR_BLACK,CLR_WHITE,.T.,,,,"",,,,,,, )
	oLstProc:Reset()
	oLstProc:align:= CONTROL_ALIGN_ALLCLIENT 
	//oLstProc:Disable()

	oJanMand:lEscClose	:= .F. //Nao permite sair ao se pressionar a tecla ESC.
	oJanMand:lCentered	:= .T.
	oJanMand:Activate(,,,.T.)

Return

//Função para validar se pode fechar a tela caso esteja em processamento
Static Function VldSaid()
	IF !lProcOK
		oJanMand:End()
	EndIF
Return .T.

//Função para Adicionar Linha no ListBox
Static Function AddList(cTexto)
	Local cPreTxt:= OEMToANSI(FWTimeStamp(2)) + " >> "+cTexto

	oLstProc:Add(cPreTxt)
	oLstProc:Refresh()
	oJanMand:Refresh()

Return .T.

//Função para validar se alguma nota já está lançada.
Static Function PesqSF1 (cTmpCtrle)
	Local lRet			:= .F.
	Local aAreaAtu 		:= getarea()
	Local aAreaPAE 		:= PAE->(getarea())
	Local aAreaSF1		:= SF1->(getarea())
	Local cF1_DOC		:= ""
	Local cF1_SERIE		:= ""
	Local cF1_FORNECE	:= ""
	Local cF1_LOJA		:= ""

	dbSelectArea("PAE")
	dbSelectArea("SF1")
	PAE->(dbsetOrder(1))
	If PAE->(dbSeek(xFilial("PAE")+cTmpCtrle))
		While PAE->(!eof() .and. PAE->PAE_FILIAL == xFilial("PAE") .AND. PAE->PAE_CTRLE == cTmpCtrle)

			cF1_DOC     := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_NFPROD,PC2->PC2_NOTA)
			cF1_SERIE   := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_SERPRO,PC2->PC2_SERIE)
			cF1_FORNECE := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_PRODUT,PC2->PC2_CLIFOR)
			cF1_LOJA    := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_LOJA  ,PC2->PC2_LOJA)

			SF1->(DBSetOrder(1)) //F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA
			IF SF1->(DBSeek(FwXFilial("SF1")+cF1_DOC+cF1_SERIE+cF1_FORNECE+cF1_LOJA))
				Help(NIL, NIL, "Documento Fiscal", NIL, "Processo Cancelado. Já existem notas lançadas ("+Alltrim(cF1_DOC)+"/"+Alltrim(cF1_SERIE)+")." , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique nos lançamentos de entrada das notas."})
				lRet := .T.
				Exit
			EndIF

			PAE->(dbSkip())
		EndDo
	EndIF

	RestArea(aAreaSF1)
	RestArea(aAreaPAE)
	RestArea(aAreaAtu)

Return lRet

//Função para verificar se o campo de Natureza está preenchido
Static Function PesqSA2(cTmpCtrle)
	Local lRet			:= .F.
	Local aAreaAtu 		:= getarea()
	Local aAreaPAE 		:= PAE->(getarea())
	Local cF1_FORNECE	:= ""
	Local cF1_LOJA		:= ""
	Local cNatur		:= ""

	dbSelectArea("PAE")
	PAE->(dbsetOrder(1))
	If PAE->(dbSeek(xFilial("PAE")+cTmpCtrle))
		While PAE->(!eof() .and. PAE->PAE_FILIAL == xFilial("PAE") .AND. PAE->PAE_CTRLE == cTmpCtrle)

			cF1_FORNECE := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_PRODUT,PC2->PC2_CLIFOR)
			cF1_LOJA    := IIF(PAE->PAE_PERPRD != 100,PAE->PAE_LOJA  ,PC2->PC2_LOJA)

			cNatur:= Alltrim(POSICIONE("SA2",1,XFILIAL("SA2")+cF1_FORNECE+cF1_LOJA,"A2_NATUREZ"))
			IF Empty(cNatur)
				Help(NIL, NIL, "Documento Fiscal", NIL, "Existe produtor ("+Alltrim(cF1_FORNECE)+"/"+Alltrim(cF1_LOJA)+")sem Natureza dentro do cadastro do Fornecedor." , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique no cadastro de fornecedor o campo de Natureza."})
				lRet := .T.
				Exit
			EndIF
			PAE->(dbSkip())
		EndDo
	EndIF

	RestArea(aAreaPAE)
	RestArea(aAreaAtu)

Return lRet

//Função para chamar a rotina de criação de nota fiscal
Static Function CriaNota(aCabDoc, aItemDoc, cTipNota)
	Local lRet 				:= .T.
	Local aAreaAtu 			:= getarea()
	local cMsgErro          := ""
	local cLogPath          := SuperGetMV("MV_LOGPATH",,"logs")  //Pasta para gravacao do log de erro pela funcao Mostraerro().  
	local cArqLog           := ""
	Private nConsulta		:= 0 // variavel para controlar quantidade de tentativas de transmissão

	Private lMsErroAuto 	:= .F. // variável que define que o help deve ser gravado no arquivo de log e que as informações estão vindo à partir da rotina automática.
	Private lMsHelpAuto		:= .F. // força a gravação das informações de erro em array para manipulação da gravação ao invés de gravar direto no arquivo temporário 
	Private lAutoErrNoFile	:= .F. //Essa variável controle que o Log deve ser armazenado em memória e não em um arquivo

	//Begin Transaction

		IF cTipNota == "P" //lançamento de Pré-Nota
			Pergunte("MTA140",.F.)//Restaura grupo de perguntas da rotina MATA140.
			MSExecAuto({|x,y,z| MATA140(x,y,z)}, aCabDoc, aItemDoc, 3)
		Else
			MSExecAuto({|x,y,z| MATA103(x,y,z)}, aCabDoc, aItemDoc, 3)
		EndIF


		IF !lMsErroAuto
			lRet := .T.

			IF cTipNota == "P" //lançamento de Pré-Nota
				AddList("Lançamento de (Normal) Pré-Nota/Serie/Filial: "+Alltrim(SF1->F1_DOC)+"/"+Alltrim(SF1->F1_SERIE)+"/"+FwXFilial("SF1") )
			ElseIF cTipNota == "N" //Lançamento de Nota de Produtor (NFP)
				AddList("Lançamento de (NFP) Nota/Serie/Filial: "+Alltrim(SF1->F1_DOC)+"/"+Alltrim(SF1->F1_SERIE)+"/"+FwXFilial("SF1") )
			ElseIF cTipNota == "S" //lançamento de Contra-Nota (SPED)
				AddList("Lançamento de (SPED) Nota/Serie/Filial: "+Alltrim(SF1->F1_DOC)+"/"+Alltrim(SF1->F1_SERIE)+"/"+FwXFilial("SF1") )
			EndIF

			//Se der tudo OK e for nota de SPED, tenta fazer a transmissão.
			IF lRet .AND. cTipNota == "S"

				//transmite as nota gerada
				nConsulta	 := 0
				//AutoNfeEnv(cEmpAnt,cFilAnt,"0","2",SF1->F1_SERIE,SF1->F1_DOC,SF1->F1_DOC)
				
				//--------------------
				//Transmissão da Nfe
				//--------------------
				U_F040013A(SF1->F1_SERIE, SF1->F1_DOC, SF1->F1_DOC )
				
				U_F0405250(SF1->F1_SERIE,SF1->F1_DOC)

				If Empty(SF1->F1_CHVNFE)	
					AddList("[Erro] Transmissão (SPED) Nota/Serie/Filial: "+Alltrim(SF1->F1_DOC)+"/"+Alltrim(SF1->F1_SERIE)+"/"+FwXFilial("SF1") )
				Else	
					AddList("[OK] Transmissão (SPED) Nota/Serie/Filial: "+Alltrim(SF1->F1_DOC)+"/"+Alltrim(SF1->F1_SERIE)+"/"+FwXFilial("SF1") )
				EndIf

			EndIF

		Else
			lRet := .F.
			IF cTipNota == "P" //lançamento de Pré-Nota
				AddList("Processo cancelado - Erro na geração de Lançamento de Pré-Nota"  )
			ElseIF cTipNota == "N" //Lançamento de Nota de Produtor (NFP)
				AddList("Processo cancelado - Erro na geração de Lançamento de Nota-Produtor(NFP)"  )
			ElseIF cTipNota == "S" //lançamento de Contra-Nota (SPED)
				AddList("Processo cancelado - Erro na geração de Lançamento de Contra-Nota(SPED)"  )
			EndIF

			If (!IsBlind()) // COM INTERFACE GRÁFICA
    			MostraErro()
    		Else // EM ESTADO DE JOB
				//Mensagem de erro do execauto
				cArqLog   := GetNextAlias()+".log"
				cMsgErro :=  MostraErro(cLogPath,cArqLog)
				
				//Apaga o arquivo de LOG.
				if file(cLogPath+"\"+cArqLog)
					FErase(cLogPath+"\"+cArqLog)
				endif
			endif
			//DisarmTransaction()
		EndIf
	//End Transaction	

	RestArea(aAreaAtu)

Return lRet

Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)

	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL

	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10)
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "001.0   FREGADOLLI          138487  21/10/22 " + CHR(10) //Ajustado para pegar a hora local da filial
	@ 10,70 SAY oSay PROMPT "F0404563" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
