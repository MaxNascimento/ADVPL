#INCLUDE "TOTVS.CH"

#DEFINE ENTER Chr(10)+Chr(13)

Static cProdGen	:= SuperGetmv("MV_PROGEN",.F.,"")
Static cCliGen	:= Alltrim(SuperGetmv("MV_CLIGEN",.F.,""))
Static cCodNeg	:= SuperGetmv("FS_C040032",.F.,"02") //Código da Negociação do Contrato do Cliente.
Static cCodRota	:= AvKey(SuperGetmv("FS_C040033",.F.,"RAÇÃO"),"DTQ_ROTA") //Código da Rota
Static cCodZona	:= AvKey(SuperGetmv("FS_C040034",.F.,"ZE001"),"DUD_ZONA") //Código da Zona
Static cCodSeto	:= AvKey(SuperGetmv("FS_C040035",.F.,"SE001"),"DUD_SETOR") //Código da Setor
Static cSeqTbFr	:= AvKey(SuperGetmv("FS_C040036",.F.,"00"),"DVC_SEQTAB") //Sequência da Tabela de Frete
Static lFrtaPro	:= SuperGetmv("FS_C040037",.F.,.F.) //Considerar apenas transportadora que seja filial
Static cRegOrig := SuperGetmv("MV_CDRORI ",.F.,"I15200") //Codigo da Região do Cliente generico
Static cCompExt := AvKey(SuperGetmv("FS_C040038",.F.,"05"),"DVR_CODPAS") //Código da Componente Extra
Static cSCmpExt := AvKey(SuperGetmv("FS_C040039",.F.,"025"),"DVR_SERVIC") //Código da Serviço do Componente Extra

/*/{Protheus.doc} F0400310
Integração OMS x TMS
@type 		Function 
@author 	Sergio Compain
@since 		22/04/2019
@version 	P12.1.17
@project	0000032563
@history 	22/04/2019, Sergio Compain, Desenvolvimento inicial (MIT044 – P04003 - GAP157- Integração OMS x TMS)
@history 	26/04/2019, Reinaldo Dias e Ricardo Mendes, Ajuste na rotina para atender a SMI026
/*/
User Function F0400310(aCargaDAK, cListDAK)

	Local aArea     := { GetArea(), SF2->(GetArea()), SD2->(GetArea()), DTC->(GetArea())}
	Local nModbkp   := nModulo
	Local aCabDTC   := {}
	Local aItemDTC  := {}
	Local cNrLoteNF := ""
	Local nNotas    := 0
	Local nFazNota	:= 0
	Local cContrato := ""
	Local cSerDoc   := ""
	Local cDocTran  := ""
	Local cTabFre   := ""
	Local cTipTab   := ""
	Local cServic   := ""
	Local cCodEmbal	:= ""
	Local cRegRem   := ""
	Local cCliRem   := ""
	Local cLojRem   := ""
	Local cRegDest	:= ""
	Local cViagem	:= ""
	Local cCNPTra   := ""
	Local cCodMotor	:= ""
	Local cCodPlaca	:= ""
	Local cTipVeic	:= ""
	Local cClassGFE	:= ""
	Local cTpOpeGFE	:= ""
	Local cVeic02	:= ""
	Local cVeic03	:= ""
	Local nRECNO_F2	:= 0
	Local lSucesso	:= .T.
	Local nTotalFat	:= 0

	Local aListaDAK	:= Separa(cListDAK,'/',.f.)
	Local nFazLst	:= 0
	Local aDAKGera	:= {}
	Local cMsgTmp	:= ""

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.
	Private aMsgErro	:= {}

	nModulo := 43  //mudo para o modulo TMS

	//Função para capturar Cliente, Loja, Região referente a Remetente (Empresa)
	IF !fRegRemen( @cCliRem, @cLojRem, @cRegRem )
		AEval(aArea, {|area| RestArea(area)})	
		Return()
	EndIF

	//Função que verifica se o cliente é do exterior para carregar os parâmetros especificos
	fCarregaTG(aCargaDAK) 

	//Função para capturar Dados relacionados ao Contrato x Cliente Generico
	IF !fCtrClGen (@cContrato, @cTabFre, @cTipTab, @cServic)
		AEval(aArea, {|area| RestArea(area)})	
		Return()
	EndIF

	//Função para captuar Dados relacionados ao Documento de Transporte x Tributação
	IF !fDocTrib(cCliGen, @cDocTran, @cSerDoc)
		AEval(aArea, {|area| RestArea(area)})	
		Return()		
	EndIF

	//Percorrer todas as cargas que foram geradas
	For nFazLst := 1 to Len(aListaDAK)
		
		aMsgErro	:= {}
		lSucesso	:= .T.
		
		//Achar a quantidade de notas que estão vinculadas as cargas
		aDAKGera := AchaDAK(aListaDAK[nFazLst], aCargaDAK )	
		IF Empty(aDAKGera)
			aadd(aMsgErro,"Não foi possivel encontrar as notas que estão vinculadas a carga["+cValToChar(aListaDAK[nFazLst])+"](DAK)!!!" )
			aadd(aMsgErro,"Dados Complementares")
			aadd(aMsgErro,"Carga:"+cValToChar(aListaDAK[nFazLst]))
			lSucesso := .F.
			exit
		EndIF

		//Funçao para captuar dados relacionados a Logistica
		If LocDAK(aDAKGera[1,1], aDAKGera[1,2])
			cCodPlaca 	:= DAK->DAK_CAMINH
			cClassGFE	:= DAK->DAK_CDCLFR
			cTpOpeGFE	:= DAK->DAK_CDTPOP
			cCodMotor	:= DAK->DAK_MOTORI
			cCNPTra		:= Posicione('SA4',1,xFilial('SA4')+DAK->DAK_TRANSP,'A4_CGC')
			cTipVeic 	:= Posicione("DA3",1,xFilial("DA3") + cCodPlaca,"DA3_TIPVEI")
			cVeic02		:= DAK->DAK_VEIC2
			cVeic03		:= DAK->DAK_VEIC3
			IF lFrtaPro .AND. !Empty(cCNPTra)
				IF !VldCGC(cCNPTra)  // 29/12/2021 - Ticket 13209115
					//Se não for frota propria não faz a integração
					lSucesso := .F.
					Exit
				EndiF
			EndIF
		Else
			aadd(aMsgErro,"Não foi possivel encontrar registro relacionado a carga (DAK)!!!" )
			aadd(aMsgErro,"Dados Complementares")
			aadd(aMsgErro,"Carga:"+cValToChar(aDAKGera[1,1]))
			aadd(aMsgErro,"Seq. Carga:"+cValToChar(aDAKGera[1,2]))
			
			lSucesso := .F.
			Exit
		EndIF

		//Array aDAKGera
		//aDAKGera[x,1] = F2_CARGA
		//aDAKGera[x,2] = F2_SEQCAR
		//aDAKGera[x,3] = F2_CLIENTE
		//aDAKGera[x,4] = F2_LOJA
		//aDAKGera[x,5] = R_E_C_N_O_ SF2REC

		//1 - Criação da DTQ (Viagem)
		cViagem   := VerCodDTQ() //Busca a sequência da tabela DTQ
		fCriaDTQ(cViagem, cTpOpeGFE, cClassGFE) //Criação da viagem - Tabela DTQ

		//2 - Criar tabela DTP (Lote de Entrada de NF)
		nNotas	  := Len(aDAKGera) // Pegar total de notas para criar lote com a quantidade de notas a serem vinculadas
		cNrLoteNF := F0400311(nNotas, cViagem) //Criação do Lote de Notas x Viagem - Tabela DTP

		If Empty(cNrLoteNF)
			aadd(aMsgErro,"Não foi possivel criar o Lotes de Entrada de Notas Fiscais!. Verificar cadastro de Lote de Nota(DTP)." )
			aadd(aMsgErro,"Dados Complementares")
			aadd(aMsgErro,"Lote NFe:"+cValToChar(cNrLoteNF))
			lSucesso := .F.
			Exit
		EndIf

		//3 - Criar Tabela DTR (Complemento de Viagem - Veiculo)
		IF (Empty(cViagem) .OR. Empty(cCodPlaca))
			aadd(aMsgErro,"Codigo da viagem ou Codigo da Placa estão vazios. Validação para criar tabela DTR." )
			aadd(aMsgErro,"Dados Complementares")
			aadd(aMsgErro,"Viagem: "+cValToChar(cViagem))
			aadd(aMsgErro,"Placa: "+cValToChar(cCodPlaca))
			lSucesso := .F.
			Exit
		EndIF
		fCriaDTR(cViagem, cCodPlaca, cVeic02, cVeic03)

		//4 - Criar Tabela DUP (Complemento de Viagem - Motorista)
		IF (Empty(cViagem) .OR. Empty(cCodPlaca) .OR. Empty(cCodMotor))
			aadd(aMsgErro,"Codigo da viagem, Codigo da Placa ou Codigo do Motorista estão vazios. Validação para criar tabela DUP." )
			aadd(aMsgErro,"Dados Complementares")
			aadd(aMsgErro,"Viagem: "+cValToChar(cViagem))
			aadd(aMsgErro,"Placa: "+cValToChar(cCodPlaca))
			aadd(aMsgErro,"Motorista: "+cValToChar(cCodMotor))
			lSucesso := .F.
			Exit
		EndIF
		fCriaDUP(cViagem, cCodPlaca, cCodMotor)

		nTotalFat := 0

		//5 - Criar tabela DTC (Notas de Clientes)
		For nFazNota := 1 to nNotas

			nRECNO_F2 := aDAKGera[nFazNota, 5]

			//Limpar arquivos antes de iniciar processo
			aCabDTC		:= {}
			aItemDTC	:= {}

			//Função para capturar os dados da Região de Calculo do Destinário (Cliente)
			IF !fRegDesti(nRECNO_F2, @cRegDest)
				lSucesso := .F.
				Exit
			EndIf

			//Função para verificar se tabela de frete origem e destino estão registrados
			DBSelectArea("DT0")
			DT0->(dbSetOrder(1))//DT0_FILIAL+DT0_TABFRE+DT0_TIPTAB+DT0_CDRORI+DT0_CDRDES+DT0_CODPRO
			IF !DT0->( MsSeek(xFilial('DT0')+AvKey(cTabFre,"DT0_TABFRE")+AvKey(cTipTab,"DT0_TIPTAB")+AvKey(cRegRem,"DT0_CDRORI")+AvKey(cRegDest,"DT0_CDRDES")))
				aadd(aMsgErro,"Não foi possivel encontrar registro relacionado a tabela de frete TMS (DT0)!. Verificar cadastro tabela de frete (DT0)." )
				aadd(aMsgErro,"Dados Complementares")
				aadd(aMsgErro,"Tabela Frete: "+cValToChar(cTabFre))
				aadd(aMsgErro,"Tipo Tabela: "+cValToChar(cTipTab))
				aadd(aMsgErro,"Cod. Reg. Rem.: "+cValToChar(cRegRem))
				aadd(aMsgErro,"Cod. Reg. Dest.: "+cValToChar(cRegDest))
				lSucesso := .F.
				Exit
			EndIF

			//Posicionar no registro dentro da SF2
			DBSelectArea("SF2")    
			DBgoto(nRECNO_F2) 

			nTotalFat += SF2->F2_VALBRUT

			DBSelectArea("SD2")
			DBSetOrder(3) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
			DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)

			IF !Empty(SF2->F2_ESPECI1)
				cCodEmbal:= IIF(ExistCpo("SX5","MG"+Alltrim(SF2->F2_ESPECI1)),Alltrim(SF2->F2_ESPECI1) ,"CX")
			Else
				cCodEmbal := "CX"
			EndIF

			//5.1 - Criação do Cabeçalho da DTC
			aCabDTC:= {;
			{"DTC_FILORI"	,SF2->F2_FILIAL  								, Nil},; //Filial de Origem
			{"DTC_LOTNFC"	,cNrLoteNF       								, Nil},; //Número Lote 
			{"DTC_DATENT"	,dDataBase       								, Nil},; //Data da Entrada 
			{"DTC_CLIREM"	,cCliRem         								, Nil},; //Cod. Remetente
			{"DTC_LOJREM"	,cLojRem         								, Nil},; //Loja Remetente
			{"DTC_CLIDES"	,SF2->F2_CLIENTE 								, Nil},; //Cod. Destinatário
			{"DTC_LOJDES"	,SF2->F2_LOJA    								, Nil},; //Loja Destinatário
			{"DTC_DEVFRE"	,"1"             								, Nil},; //Devedor do Frete - 1=Remetente;2=Destinatario;3=Consignatario;4=Despachante 
			{"DTC_CLIDEV"	,cCliRem         								, Nil},; //Devedor - Cliente Devedor do Frete
			{"DTC_LOJDEV"	,cLojRem         								, Nil},; //Loja Devedor - Loja Cliente Devedor do Frete
			{"DTC_CLICAL"	,cCliRem         								, Nil},; //Cliente para Calculo 
			{"DTC_LOJCAL"	,cLojRem         								, Nil},; //Loja Cliente para Calculo
			{"DTC_TIPFRE"	,"1"             								, Nil},; //Tipo do Frete - 1=CIF;2=FOB 
			{"DTC_SERTMS"	,"3"             								, Nil},; //Servico de Transporte - 1=Rodoviario / 2=Aereo / 3=Fluvial. 
			{"DTC_TIPTRA"	,"1"             								, Nil},; //Tipo Transporte 
			{"DTC_SERVIC"	,cServic         								, Nil},; //Serviço
			{"DTC_TIPNFC"	,"0"             								, Nil},; //Tipo Nf Cli. - 0=Normal;1=Devolucao;2=SubContratacao;3=Nao Fiscal;4=Exportacao;5=Redesp;6=Nao Fiscal 1;7=Nao Fiscal 2;8=Serv Vincul.Multimodal 
			{"DTC_NCONTR"	,cContrato       								, Nil},; //Número do Contrato do Cliente. 
			{"DTC_CODNEG"	,cCodNeg         								, Nil},; //Código da Negociação do Contrato do Cliente. 
			{"DTC_DOCTMS"	,cDocTran        								, Nil},; //Documento de Transporte 
			{"DTC_SELORI"	,"1"             								, Nil},; //Seleciona Origem - 1=Transportadora;2=Cliente Remetente;3=Local Coleta
			{"DTC_XCROMS"	,SF2->F2_CARGA   								, Nil},;
			{"DTC_CDRORI"	,cRegOrig										, Nil}}  //Filial do Documento a ser Gerado

			//5.2 - Criação do Item da DTC
			Aadd(aItemDTC,{;
			{"DTC_FILORI" ,SF2->F2_FILIAL									, Nil},; //Filial de Origem
			{"DTC_LOTNFC" ,cNrLoteNF										, Nil},; //Número Lote 
			{"DTC_NUMNFC" ,SF2->F2_DOC										, Nil},; //Doc.Cliente 
			{"DTC_SERNFC" ,SF2->F2_SERIE									, Nil},; //Serie Docto. Cliente 
			{"DTC_CODPRO" ,cProdGen											, Nil},; //Codigo do Produto 
			{"DTC_CODEMB" ,cCodEmbal										, Nil},; //Codigo da Embalagem 
			{"DTC_EMINFC" ,SF2->F2_EMISSAO									, Nil},; //Dt.Emissao Nf Cliente 
			{"DTC_QTDVOL" ,IIF(Empty(SF2->F2_VOLUME1),1,SF2->F2_VOLUME1)	, Nil},; //Quantidade de Volumes da Nota Fiscal do Cliente
			{"DTC_PESO"   ,SF2->F2_PBRUTO									, Nil},; //Peso da Nota Fiscal do Cliente. 
			{"DTC_VALOR"  ,SF2->F2_VALBRUT									, Nil},; //Valor da Nota Fiscal do Cliente
			{"DTC_CF"     ,SD2->D2_CF										, Nil},; //CFOP
			{"DTC_USUAGD" ,__cUserID										, Nil},; //Codigo do Usuario Responsável pelo Agendamento de Entrega 
			{"DTC_DOCREE" ,"2"												, Nil},; //Documento de Transporte 
			{"DTC_PRVENT" ,dDataBase+1										, Nil},; //Hora Previsao de Entrega 
			{"DTC_NFENTR" ,"2"												, Nil},; //Nome Expedidor 
			{"DTC_EDI"    ,'2'												, Nil},; //Nota Fiscal do EDI Indica se a Nota Fiscal é de EDI (Electronic Data Interchange). 
			{"DTC_XPDVEN" ,SD2->D2_PEDIDO									, Nil}}) //PEDIDO

			lMsErroAuto := .F.

			aCabDTC := FWVetByDic( aCabDTC , "DTC", .F., 1 )
			aItemDTC:= FWVetByDic( aItemDTC, "DTC", .T., 1 )

			Begin Transaction
				// Executa rotina TMSA050
				MSExecAuto({|u,v,x,y,z| TMSA050(u,v,x,y,z)},aCabDTC,aItemDTC,,,3)
				If lMsErroAuto
					lSucesso := .F.
					if (!isblind()) // COM INTERFACE GRÁFICA
						MostraErro() // TELA
					else // EM ESTADO DE JOB
						//Mensagem de erro do execauto
						cArqLog   	:= GetNextAlias()+".log"
						cMsgErro 	:=  MostraErro(cLogPath,cArqLog)

						//Apaga o arquivo de LOG.
						if file(cLogPath+"\"+cArqLog)
							FErase(cLogPath+"\"+cArqLog)
						endif
					endif
					DisarmTransaction()
				EndIF
				
			End Transaction
			
		Next nFazNota

		IF lSucesso

			//Criar Gravação da DTR para componente Extra
			IF nNotas > 1 
				aAreaDTC	:= DTC->(getarea())
				
				DBSelectArea("DTC") 
				DTC->( dbSetOrder(1) ) //DTC_FILIAL+DTC_FILORI+DTC_LOTNFC+DTC_CLIREM+DTC_LOJREM+DTC_CLIDES+DTC_LOJDES+DTC_SERVIC+DTC_CODPRO+DTC_NUMNFC+DTC_SERNFC
				IF DTC->( MsSeek( xFilial("DTC") + cFilAnt + cNrLoteNF + cCliRem + cLojRem + SF2->F2_CLIENTE + SF2->F2_LOJA) )
					fCriaDVR(cNrLoteNF, cCliRem, cLojRem, SF2->F2_CLIENTE, SF2->F2_LOJA, SF2->F2_DOC , SF2->F2_SERIE, nNotas -1)
				EndIF
				
				RestArea(aAreaDTC)
				
			EndIF

			//6 - Calcular Frete
			IF fCalcFret(cNrLoteNF)

				DBSelectArea("DT6") 
				DT6->( dbSetOrder(2) )
				IF DT6->( MsSeek( xFilial("DT6") + cFilAnt + cNrLoteNF ) )

					//7 - Criar Tabela DUD (Movimento da Viagem)
					fCriaDUD(DT6->DT6_DOC, DT6->DT6_SERIE, "", DT6->DT6_CDRCAL, cViagem, DT6->DT6_CLIDES, DT6->DT6_LOJDES)

					//8 - Criar Tabela DVU - (Tipo Veículo Nota Fiscal)
					fCriaDVU(DT6->DT6_DOC, DT6->DT6_SERIE, DT6->DT6_CLIREM, DT6->DT6_LOJREM, cNrLoteNF, cTipVeic)
						
					//9 - Criar Tabela DM3 - (Documentos da Viagem Mod.3)
					fCriaDM3(DT6->DT6_DOC, DT6->DT6_SERIE, cViagem)

					//10 - Criar Tabela DM4 - (Planejamento da Viagem Mod.3)
					fCriaDM4(cViagem)

					//11 - Criar Tabela DM6 - (Viagem Carregada)
					fCriaDM6(cViagem)

					//12 - Criar Tabela DM7 - (Veiculos Carregados)
					fCriaDM7(cViagem, cCodPlaca, cVeic02, cVeic03)

					//13 - Criar Tabela DTA - (Carregamento)
					fCriaDTA(DT6->DT6_DOC, DT6->DT6_SERIE, cViagem, DTC->DTC_QTDVOL, cCodPlaca, DT6->DT6_VALFRE)
				EndIF

			EndIF
		Else
			Exit
		EndIF

	Next nFazLst

	IF !Empty(aMsgErro)
		cMsgTmp := ""
		
		For nFazLst := 1 to Len(aMsgErro)
			cMsgTmp += Alltrim(cValToChar(aMsgErro[nFazLst]))+ENTER
		Next nFazLst
	
		IF !Empty(cMsgTmp)
			MsgDtlhe("Inconsistência de Integração", "Durante o processo de integração OMS x TMS foi gerado inconsistência(s)."+ENTER+;
					   "Clique em 'Detalhes' para visualizar as informações.", cMsgTmp)
		EndIF
	EndIF
	
	AEval(aArea, {|area| RestArea(area)})	

	nModulo := nModbkp  //restauro o modulo origem

Return


/*/{Protheus.doc} F0400311
description
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 10/06/2020
@param nLote
@return cRet
/*/
Static Function F0400311(nLote, cTmpVge)  // Função de MSExecAuto do Lote

	Local aAreaAtu := getarea()
	Local aCab     := {}
	Local cRet

	Private lMsErroAuto := .F. //Como variável já foi declarada acima, aqui ela foi foi declarada novamente. Caso contrario deve ser declarada com private

	AAdd(aCab,{'DTP_QTDLOT', nLote  ,Nil})
	AAdd(aCab,{'DTP_QTDDIG', 0      ,Nil})
	AAdd(aCab,{'DTP_STATUS','1'     ,Nil}) //-- Em aberto 
	AAdd(aCab,{'DTP_TIPLOT','1'     ,Nil}) //-- Lote Normal
	AAdd(aCab,{'DTP_VIAGEM',cTmpVge ,Nil}) //-- Numero da Viagem amarrada ao Lote

	// Executa rotina TMSA170
	MSExecAuto({|x,y| cRet := TMSA170(x,y)},aCab,3)

	// Retorna Resultado do Processo
	If lMsErroAuto
		if (!isblind()) // COM INTERFACE GRÁFICA
			MostraErro() // TELA
		else // EM ESTADO DE JOB
			//Mensagem de erro do execauto
			cArqLog   	:= GetNextAlias()+".log"
			cMsgErro 	:=  MostraErro(cLogPath,cArqLog)

			//Apaga o arquivo de LOG.
			if file(cLogPath+"\"+cArqLog)
				FErase(cLogPath+"\"+cArqLog)
			endif
		endif
		cRet := Space(TamSX3('DTP_LOTNFC')[1])
	Else
		cRet := DTP->DTP_LOTNFC 
	EndIf

	Restarea(aAreaAtu)

Return cRet


/*/{Protheus.doc} fAtuPerg
description
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 10/06/2020
@param cPergAux, character, param_description
@param cParAux, character, param_description
@param xConteud, param_type, param_description
@return return_type, return_description
/*/
Static Function fAtuPerg(cPergAux, cParAux, xConteud)

	Local aArea      := GetArea()
	Local nPosPar    := 14
	Local nLinEncont := 0
	Local aPergAux   := {}
	Default xConteud := ''

	//Se não tiver pergunta, ou não tiver ordem
	If Empty(cPergAux) .Or. Empty(cParAux)
		Return
	EndIf

	//Chama a pergunta em memória
	Pergunte(cPergAux, .F., /*cTitle*/, /*lOnlyView*/, /*oDlg*/, /*lUseProf*/, @aPergAux)

	//Procura a posição do MV_PAR
	nLinEncont := aScan(aPergAux, {|x| Upper(Alltrim(x[nPosPar])) == Upper(cParAux) })

	//Se encontrou o parâmetro
	If nLinEncont > 0
		//Caracter
		If ValType(xConteud) == 'C'
			&(cParAux+" := '"+xConteud+"'")
			//Data
		ElseIf ValType(xConteud) == 'D'
			&(cParAux+" := sToD('"+dToS(xConteud)+")'")
			//Numérico ou Lógico
		ElseIf ValType(xConteud) == 'N' .Or. ValType(xConteud) == 'L'
			&(cParAux+" := "+cValToChar(xConteud)+"")
		EndIf

		//Chama a rotina para salvar os parâmetros
		__SaveParam(cPergAux, aPergAux)
	EndIf

	RestArea(aArea)
Return


/*/{Protheus.doc} fCriaDTQ
Função para Criar tabela DTQ (Viagem)
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cCodViag, character, param_description
@param cTpOpe, character, param_description
@param cClass, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDTQ(cCodViag, cTpOpe, cClass)
	Local aAreaAtu 	:= getarea()

	Default cTpOpe	:= "LOGFRIG"
	Default cClass	:= "FRIG"

	Reclock("DTQ",.T.)
	DTQ->DTQ_FILIAL	:= xFilial("DTQ")
	DTQ->DTQ_FILORI	:= cFilAnt
	DTQ->DTQ_VIAGEM	:= cCodViag        
	DTQ->DTQ_TIPVIA	:= "1"            
	DTQ->DTQ_ROTA	:= cCodRota
	DTQ->DTQ_DATGER	:= dDataBase      
	DTQ->DTQ_HORGER	:= StrTran(Left(Time(),5),":","") 
	DTQ->DTQ_SERTMS	:= "3"
	DTQ->DTQ_TIPTRA	:= "1"
	DTQ->DTQ_FILATU	:= cFilAnt
	DTQ->DTQ_FILDES	:= cFilAnt
	DTQ->DTQ_STATUS	:= "1"            
	DTQ->DTQ_PAGGFE	:= "2"           
	DTQ->DTQ_CDTPOP	:= cTpOpe        
	DTQ->DTQ_CDCLFR	:= cClass           
	DTQ->(MsUnlock())

	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDTR
Função para Criar Tabela DTR (Complemento de Viagem - Veiculo)
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpVge, character, param_description
@param cTmpVeic, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDTR(cTmpVge, cTmpVeic, cVeic02, cVeic03)
	Local aAreaAtu 	:= getarea()

	DTR->(dbSetOrder(1)) //DTR_FILIAL+DTR_FILORI+DTR_VIAGEM+DTR_ITEM
	If DTR->(MsSeek(FwxFilial('DTR')+cFilAnt+cTmpVge))
		Reclock("DTR",.F.)
	Else
		Reclock("DTR",.T.)
	EndIF
	DTR->DTR_FILIAL := xFilial("DTR")
	DTR->DTR_FILORI := cFilAnt
	DTR->DTR_VIAGEM := cTmpVge
	DTR->DTR_FILVGE := xFilial("DTQ")
	DTR->DTR_ITEM   := "01"
	DTR->DTR_CODVEI := cTmpVeic
	If !EmpTy(cVeic02)
		DTR->DTR_CODRB1	:= cVeic02
	EndIf	
	If !Empty(cVeic03)
		DTR->DTR_CODRB2	:= cVeic03
	EndIf	
	DTR->DTR_FRECAL := "2"
	DTR->DTR_REBTRF := "2"
	DTR->DTR_CALRB1 := "2"
	DTR->DTR_CALRB2 := "2"
	DTR->DTR_CALRB3 := "2"
	DTR->DTR_TITADI := "2"
	DTR->DTR_TPCIOT := "1"
	DTR->DTR_CODFOR := Posicione("DA3",1,xFilial("DA3")+DTR->DTR_CODVEI,"DA3_CODFOR")
	DTR->DTR_LOJFOR := Posicione("DA3",1,xFilial("DA3")+DTR->DTR_CODVEI,"DA3_LOJFOR")					
	DTR->DTR_CREADI := Posicione("DA3",1,xFilial("DA3")+DTR->DTR_CODVEI,"DA3_CODFOR")
	DTR->DTR_LOJCRE := Posicione("DA3",1,xFilial("DA3")+DTR->DTR_CODVEI,"DA3_LOJFOR")					
	DTR->DTR_NOMCRE := Posicione('SA2',1,xFilial("SA2")+DTR->DTR_CREADI+DTR->DTR_LOJCRE,'A2_NOME')
	DTR->DTR_TIPCRG := "2" 
	DTR->DTR_TITADI := "2" 
	DTR->DTR_DTFMCI := dDataBase 
	DTR->DTR_QTDSAQ := 0 
	DTR->DTR_QTDTRA := 0 
	DTR->(MsUnlock())

	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDUP
Função para Criar Tabela DUP (Complemento de Viagem - Motorista)
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpVge, character, param_description
@param cTmpVeic, character, param_description
@param cTmpMoto, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDUP(cTmpVge, cTmpVeic, cTmpMoto)
	Local aAreaAtu 	:= getarea()

	DUP->( dbSetOrder(1) )
	If DUP->(dbSeek(FWxFilial("DUP")+cFilAnt+ cTmpVge) )
		Reclock("DUP",.F.)
	Else
		Reclock("DUP",.T.)
	EndIF
	DUP->DUP_FILIAL := xFilial("DTR")
	DUP->DUP_FILORI := cFilAnt
	DUP->DUP_VIAGEM := cTmpVge
	DUP->DUP_ITEDTR := "01"
	DUP->DUP_CODVEI := cTmpVeic
	DUP->DUP_CODMOT := cTmpMoto
	DUP->DUP_CONDUT := "1" //1=Principal
	DUP->(MsUnlock())

	Restarea(aAreaAtu)

Return .T.			


/*/{Protheus.doc} fCriaDVU
Função para criar a tabela DVU - (Tipo Veículo Nota Fiscal)
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpNota, character, param_description
@param cTmpSer, character, param_description
@param cTmpCli, character, param_description
@param cTmpLoj, character, param_description
@param cTmpLot, character, param_description
@param cTmpTpVe, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDVU(cTmpNota, cTmpSer, cTmpCli, cTmpLoj, cTmpLot, cTmpTpVe)
	Local aAreaAtu 	:= getarea()
	Local cSeek		:= ""

	DVU->(dbSetOrder(2))
	IF DVU->(MsSeek(cSeek:=xFilial('DVU')+ cFilAnt+cTmpLot+cTmpNota+cTmpSer+cTmpCli+cTmpLoj))
		Do While !DVU->(Eof()) .And. DVU->(DVU_FILIAL+DVU_FILORI+DVU_LOTNFC+DVU_NUMNFC+DVU_SERNFC+DVU_CLIREM+DVU_LOJREM) == cSeek
			RecLock("DVU", .F.)
			DVU->DVU_FILIAL := xFilial('DVU')
			DVU->DVU_ITEM   := "01"
			DVU->DVU_FILORI := cFilAnt
			DVU->DVU_NUMNFC := cTmpNota
			DVU->DVU_SERNFC := cTmpSer
			DVU->DVU_CLIREM := cTmpCli
			DVU->DVU_LOJREM := cTmpLoj
			DVU->DVU_LOTNFC := cTmpLot
			DVU->DVU_TIPVEI := cTmpTpVe
			DVU->DVU_QTDVEI := 1
			DVU->(MsUnLock())
			DVU->(dbSkip())
		EndDo
	Else
		Reclock("DVU",.T.)
		DVU->DVU_FILIAL := xFilial('DVU')
		DVU->DVU_ITEM   := "01"
		DVU->DVU_FILORI := cFilAnt
		DVU->DVU_NUMNFC := cTmpNota
		DVU->DVU_SERNFC := cTmpSer
		DVU->DVU_CLIREM := cTmpCli
		DVU->DVU_LOJREM := cTmpLoj
		DVU->DVU_LOTNFC := cTmpLot
		DVU->DVU_TIPVEI := cTmpTpVe
		DVU->DVU_QTDVEI := 1
		DVU->(MsUnLock())	
	EndIF

	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDUD
Função para criar a Tabela DUU - Registro Pendências
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cDTCDoc, character, param_description
@param cDTCSerie, character, param_description
@param cDTCPedV, character, param_description
@param cTmpCal, character, param_description
@param cTmpVge, character, param_description
@param cCliDes, character, param_description
@param cLojDes, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDUD(cDTCDoc, cDTCSerie, cDTCPedV, cTmpCal, cTmpVge, cCliDes, cLojDes)
	Local aAreaAtu 	:= getarea()
	Local cSeekDUD	:= ""
	Local xSVCENT 	:= GetMV("MV_SVCENT",,"002") // 22/12/2021 - Ticket 13209115
	DUD->(DbSetOrder(1)) //DUD_FILIAL+DUD_FILDOC+DUD_DOC+DUD_SERIE+DUD_FILORI //Retirado campo DUD_VIAGEM chamado 144117
	If	DUD->(dbSeek(cSeekDUD:= xFilial('DUD')+cFilAnt+cDTCDoc+cDTCSerie+cFilAnt))
		While DUD->(!Eof() .And. DUD_FILIAL+DUD_FILDOC+DUD_DOC+DUD_SERIE+DUD_FILORI == cSeekDUD)
			Reclock("DUD",.F.)
				DUD->DUD_FILDOC	:= cFilAnt
				DUD->DUD_DOC	:= cDTCDoc
				DUD->DUD_SERIE	:= cDTCSerie
				DUD->DUD_FILORI	:= cFilAnt
				DUD->DUD_VIAGEM	:= cTmpVge
				DUD->DUD_FILORI := cFilAnt
				DUD->DUD_SERTMS := "3"
				DUD->DUD_TIPTRA := "1"
				//DUD->DUD_SERVIC := GetMV("MV_SVCENT",,"002") // 22/12/2021 - Ticket 13209115
				DUD->DUD_SERVIC := xSVCENT // 22/12/2021 - Ticket 13209115
				DUD->DUD_GERROM := "2"
				DUD->DUD_DOCTRF	:= "2"
				DUD->DUD_SEQUEN := StrZero(1,TamSX3('DUD_SEQUEN')[1])     
				DUD->DUD_SEQENT := StrZero(1,TamSX3('DUD_SEQENT')[1])     
				DUD->DUD_ZONA   := cCodZona     
				DUD->DUD_SETOR  := cCodSeto 
				DUD->DUD_XPDVEN := cDTCPedV 
				DUD->DUD_STATUS := "3"
				DUD->DUD_CDRDES	:= cTmpCal
				DUD->DUD_CDRCAL := cTmpCal
				DUD->DUD_FILATU := cFilAnt
				DUD->DUD_STROTA := "3"  //De outra Rota
				DUD->DUD_CEPENT := TmsCEPEnt(cCliDes,cLojDes,,"")
			DUD->( MsUnLock() )

			DUD->(dbSkip())
		EndDo
	Else
		Reclock("DUD",.T.)
			DUD->DUD_FILIAL	:= xFilial('DUD')
			DUD->DUD_FILDOC	:= cFilAnt
			DUD->DUD_DOC	:= cDTCDoc
			DUD->DUD_SERIE	:= cDTCSerie
			DUD->DUD_FILORI	:= cFilAnt
			DUD->DUD_VIAGEM	:= cTmpVge
			DUD->DUD_FILORI := cFilAnt
			DUD->DUD_SERTMS := "3"
			DUD->DUD_TIPTRA := "1"
			//DUD->DUD_SERVIC := GetMV("MV_SVCENT",,"002") // 22/12/2021 - Ticket 13209115
			DUD->DUD_SERVIC := xSVCENT// 22/12/2021 - Ticket 13209115
			DUD->DUD_GERROM := "2"
			DUD->DUD_DOCTRF	:= "2"
			DUD->DUD_SEQUEN := StrZero(1,TamSX3('DUD_SEQUEN')[1])     
			DUD->DUD_SEQENT := StrZero(1,TamSX3('DUD_SEQENT')[1])     
			DUD->DUD_ZONA   := cCodZona     
			DUD->DUD_SETOR  := cCodSeto 
			DUD->DUD_XPDVEN := cDTCPedV 
			DUD->DUD_STATUS := "3"
			DUD->DUD_CDRDES	:= cTmpCal
			DUD->DUD_CDRCAL := cTmpCal
			DUD->DUD_FILATU := cFilAnt
			DUD->DUD_STROTA := "3"  //De outra Rota
			DUD->DUD_CEPENT := TmsCEPEnt(cCliDes,cLojDes,,"")
		DUD->(MsUnlock())
	EndIF
	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDVR
Função para criar DVR de Componente Extra
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpLote, character, param_description
@param cTmpClRem, character, param_description
@param cTmpLjRem, character, param_description
@param cTmpClDes, character, param_description
@param cTmpLjDes, character, param_description
@param cTmpNF, character, param_description
@param cTmpSer, character, param_description
@param nVlrComp, numeric, param_description
@return return_type, return_description
/*/
Static Function fCriaDVR(cTmpLote, cTmpClRem, cTmpLjRem, cTmpClDes, cTmpLjDes, cTmpNF, cTmpSer, nVlrComp)
	Local aAreaAtu 	:= getarea()
	Local lRet		:= .T.

	RecLock("DVR",.T.)
	DVR->DVR_FILIAL :=	xFilial("DVR")
	DVR->DVR_FILORI	:=	cFilAnt
	DVR->DVR_LOTNFC	:=	cTmpLote	
	DVR->DVR_CLIREM	:=	cTmpClRem
	DVR->DVR_LOJREM	:=	cTmpLjRem
	DVR->DVR_CLIDES	:=	cTmpClDes
	DVR->DVR_LOJDES	:=	cTmpLjDes
	DVR->DVR_SERVIC	:=	cSCmpExt
	DVR->DVR_NUMNFC	:=	cTmpNF
	DVR->DVR_SERNFC	:=	cTmpSer
	DVR->DVR_CODPRO	:=	cProdGen
	DVR->DVR_CODPAS :=	cCompExt
	DVR->DVR_VALOR 	:=	nVlrComp
	DVR->DVR_CODNEG :=	cCodNeg
	DVR->(MsUnlock())

	Restarea(aAreaAtu)
Return lRet


/*/{Protheus.doc} fCalcFret
Função para dispara o calculo de Frete
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpLote, character, param_description
@return return_type, return_description
/*/
Static Function fCalcFret(cTmpLote)
	Local aAreaAtu 	:= getarea()
	Local lRet := .T.

	fAtuPerg("TMB200", "MV_PAR10", 2) //mudo a pergunta para não visualizar o preview do calculo do frete
	DTP->(DbSetOrder(2))
	If DTP->(MsSeek(xFilial("DTP")+cFilAnt+cTmpLote))
		lRet:= TMSA200Prc( DTP->DTP_FILORI, DTP->DTP_LOTNFC )
	EndIf
	fAtuPerg("TMB200", "MV_PAR10", 1) //volto a pergunta para visualizar o preview do calculo do frete

	Restarea(aAreaAtu)

Return lRet


/*/{Protheus.doc} fRegRemen
Função para Trazer a Região de Calculo do Remetente (Empresa)
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTCliRem, character, param_description
@param cTLojRem, character, param_description
@param cTRegOri, character, param_description
@return return_type, return_description
/*/
Static Function fRegRemen(cTCliRem, cTLojRem, cTRegOri)
	Local lRet		:= .T.		
	Local cCodMun	:= ""
	Local aAreaAtu 	:= getarea()
	Local aCGC 		:= FWSM0Util():GetSM0Data(cEmpAnt , cFilAnt , { "M0_CGC" } ) // 22/12/2021 - Ticket 13209115

	DBSelectArea("SA1")
	DBSetOrder(3) //A1_FILIAL+A1_CGC
	//If !DBseek(xFilial("SA1")+SM0->M0_CGC)
	If !DBseek(xFilial("SA1")+aCGC[1][2]) // 22/12/2021 - Ticket 13209115
		MsgHelp("F0400310", "Remente não cadastrado", "Verificar cadastro da filial como Cliente.")
		lRet := .F.
	Else 
		IF Empty(SA1->A1_CDRDES) .AND. !Empty(SA1->A1_COD_MUN) .AND. !Empty(SA1->A1_EST)
			//Ajustar cadastro para gravar corretamente a região do cliente
			cCodMun := Posicione("DUY",6,xFilial("DUY")+SA1->A1_EST + SA1->A1_COD_MUN,"DUY_GRPVEN")  
			IF Empty(cCodMun)
				IF !fCriaDUY(SA1->A1_EST, SA1->A1_COD_MUN)
					MsgHelp("F0400310", "Não foi possivel gerar Grupos de Regiões", "Verificar cadastro da região(DUY).")
					lRet := .F.
				Else
					cCodMun := Posicione("DUY",6,xFilial("DUY")+SA1->A1_EST + SA1->A1_COD_MUN,"DUY_GRPVEN") 
				EndIF
			EndIF
			IF !Empty(cCodMun)
				SA1->( Reclock("SA1",.F.))
				SA1->A1_CDRDES := cCodMun
				SA1->( MsUnlock())
			EndIF
		EndIF
		cTCliRem := SA1->A1_COD
		cTLojRem := SA1->A1_LOJA
		cTRegOri := SA1->A1_CDRDES
	EndIf

	Restarea(aAreaAtu)

Return lRet


/*/{Protheus.doc} fRegDesti
Função para Trazer a Região de Calculo do Destinário (Cliente)description
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param nRegNota, numeric, param_description
@param cTDesti, character, param_description
@return return_type, return_description
/*/
Static Function fRegDesti(nRegNota, cTDesti)
	Local lRet 		:= .T.
	Local cCodMun	:= ""
	Local aAreaAtu 	:= getarea()

	DBSelectArea("SF2")    
	DBgoto(nRegNota) //Posiciona no registro dentro da SF2

	DBSelectArea("SA1")
	DBSetOrder(1) //A1_FILIAL+A1_COD+A1_LOJA
	DBseek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)

	//Verifica se é cliente do exterior
	If SA1->A1_EST = 'EX'
		fDestEx(nRegNota)
	Else
		IF Empty(SA1->A1_CDRDES) .AND. !Empty(SA1->A1_COD_MUN) .AND. !Empty(SA1->A1_EST)
			//Ajustar cadastro para gravar corretamente a região do cliente
			cCodMun := Posicione("DUY",6,xFilial("DUY")+SA1->A1_EST + SA1->A1_COD_MUN,"DUY_GRPVEN")
			IF Empty(cCodMun)
				IF !fCriaDUY(SA1->A1_EST, SA1->A1_COD_MUN)
					aadd(aMsgErro,"Não foi possivel gerar Grupos de Regiões!. Verificar cadastro de cliente campo (A1_CDRDES).")
					aadd(aMsgErro,"Dados Complementares")
					aadd(aMsgErro,"Cliente: "+cValToChar(SF2->F2_CLIENTE))
					aadd(aMsgErro,"Loja: "+cValToChar(SF2->F2_LOJA))
					aadd(aMsgErro,"UF: "+cValToChar(SA1->A1_EST))
					aadd(aMsgErro,"Cod. IBGE: "+cValToChar(SA1->A1_COD_MUN))
					lRet:= .F.
				Else
					cCodMun := Posicione("DUY",6,xFilial("DUY")+SA1->A1_EST + SA1->A1_COD_MUN,"DUY_GRPVEN")
				EndIF
			EndIF
			IF !Empty(cCodMun)
				SA1->( Reclock("SA1",.F.))
				SA1->A1_CDRDES := cCodMun
				SA1->( MsUnlock())
			EndIF
		EndIF
	EndIf

	cTDesti := SA1->A1_CDRDES

	Restarea(aAreaAtu)

Return lRet


/*/{Protheus.doc} fCtrClGen
Função para trazer Trazer os Dados entre Contrato x Cliente Generico
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpCtr, character, param_description
@param cTmpTbFr, character, param_description
@param cTmpTip, character, param_description
@param cTmpServ, character, param_description
@return return_type, return_description
/*/
Static Function fCtrClGen(cTmpCtr, cTmpTbFr, cTmpTip, cTmpServ)
	Local lRet := .T.
	Local aAreaAtu 	:= getarea()

	DBSelectArea("AAM")
	DBSetOrder(4) //AAM_FILIAL+AAM_CODCLI+AAM_LOJA+AAM_CONTRT
	If !DBseek(xFilial("AAM")+cCliGen)
		MsgHelp("F0400310", "Não foi possivel encontar o contrato para o Cliente : "+cCliGen+" !!", "Verificar cadastro da contrato genérico(AAM).")
		lRet := .F.
	Else
		cTmpCtr := AAM->AAM_CONTRT

		DBSelectArea("DDA")
		DBSetOrder(1) //DDA_FILIAL+DDA_NCONTR+DDA_CODNEG+DDA_ITEM
		If !DBseek(xFilial("DDA")+cTmpCtr+cCodNeg)
			MsgHelp("F0400310", "Não foi possivel encontar Servicos Negociacao Cliente - Contrato : "+cTmpCtr+" !!", "Verificar cadastro de negociação de cliente(DDA).")
			lRet := .F.
		Else
			cTmpTbFr 	:= DDA->DDA_TABFRE
			cTmpTip		:= DDA->DDA_TIPTAB
			cTmpServ	:= DDA->DDA_SERVIC
		EndIf

	EndIf

	Restarea(aAreaAtu)
Return lRet


/*/{Protheus.doc} fDocTrib
Função para captuar Dados relacionados ao Documento de Transporte x Tributação
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpGen, character, param_description
@param cTmpDoc, character, param_description
@param cTmpSer, character, param_description
@return return_type, return_description
/*/
Static Function fDocTrib(cTmpGen, cTmpDoc, cTmpSer)
	Local lRet := .T.
	Local aAreaAtu 	:= getarea()

	DBSelectArea("DV1")
	DBSetOrder(1) //DV1_FILIAL+DV1_CODCLI+DV1_LOJCLI+DV1_DOCTMS+DV1_CODPRO+DV1_TIPNFC+DV1_TIPCLI+DV1_SEQINS+DV1_REGTRI
	If !DBseek(xFilial("DV1")+cTmpGen)
		MsgHelp("F0400310", "Não foi possivel encontar a Regra de Tributação para o Cliente : "+cTmpGen+" !!", "Verificar cadastro da Regra de Tributação genérico(DV1).")
		lRet := .F.
	Else
		cTmpDoc := DV1->DV1_DOCTMS

		DBSelectArea("DUI")
		DBSetOrder(1) //DUI_FILIAL+DUI_DOCTMS
		If !DBseek(xFilial("DUI")+cTmpDoc)
			MsgHelp("F0400310", "Não foi possivel encontrar o tipo de documento : "+cTmpDoc+"  !!", "Verificar configuração de documento(DUI).")
			lRet := .F.
		Else
			cTmpSer := DUI->DUI_SERIE
			If Empty(cTmpSer)
				MsgHelp("F0400310", "Não foi possivel encontar Serie do documento : "+cTmpDoc+"  !!", "Verificar configuração de documento(DUI).")
				lRet := .F.
			EndIf
		EndIf

	EndIf

	Restarea(aAreaAtu)

Return lRet


/*/{Protheus.doc} AchaDAK
Função para trazer as notas que estão vinculadas as cargas
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 22/06/2020
@param cTmpCarg, character, param_description
@param aLista, array, param_description
@return return_type, return_description
/*/
Static Function AchaDAK(cTmpCarg, aLista)
	Local aRetDAK	:= {}
	Local nFazDAK	:= 0

	//Array aRetDAK
	//aRetDAK[x,1] = F2_CARGA
	//aRetDAK[x,2] = F2_SEQCAR
	//aRetDAK[x,3] = F2_CLIENTE
	//aRetDAK[x,4] = F2_LOJA
	//aRetDAK[x,5] = R_E_C_N_O_ SF2REC
	for nFazDAK:= 1 to Len(aLista)
		IF Alltrim(cTmpCarg) == Alltrim(aLista[nFazDAK,1])
			aadd(aRetDAK, {aLista[nFazDAK,1], aLista[nFazDAK,2],aLista[nFazDAK,3],aLista[nFazDAK,4],aLista[nFazDAK,5]})
		EndIF
	next nFazDAK	

Return aRetDAK


/*/{Protheus.doc} VerCodDTQ
description
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 11/06/2020
@return return_type, return_description
/*/
Static Function VerCodDTQ()

	Local cCodRet  	:= GetSxeNum("DTQ","DTQ_VIAGEM")
	Local aAreaAtu 	:= getarea()

	While .t.
		DBSelectArea("DTQ")
		DBSetorder(1)
		If DBseek(cFilAnt+cCodRet)
			ConFirmSX8()
			cCodRet := GetSxeNum("DTQ","DTQ_VIAGEM")
		Else
			ConFirmSX8()
			exit
		EndIf
	Enddo

	Restarea(aAreaAtu)

Return(cCodRet)


/*/{Protheus.doc} fCriaDUY
Função para criar grupo de região no TMS via ExecAuto
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 11/06/2020
@param cTmpUF, character, param_description
@param cTmpMun, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDUY(cTmpUF, cTmpMun)
	Local aAreaAtu := getarea()
	Local lRet	   := .F.
	Local aCab	   := {}
	Local nLen	   := Len(Alltrim(cTmpMun))
	Local nLenDUY  := TamSx3("DUY_GRPVEN")[1]
	Local nLenTot  := ABS(nLenDUY - nLen) 
	Local cCodGRUP := ""

	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.

	DBSelectArea('CC2')
	CC2->(DBSetOrder(1))	// Filial + Estado + municipo (codigo IBGE)
	If CC2->(DBSeek(FwXFilial("CC2") + cTmpUF + cTmpMun))
		DBSelectArea('DUY')		
		DUY->(DBSetOrder(6)) // Filial + Estado + Cd Municipio
		If !(DUY->(DBSeek(FwXFilial("DUY") + cTmpUF + cTmpMun)))
			aCab     := {}
			cCodGRUP := Right(cTmpUF,nLenTot)+Alltrim(cTmpMun)

			While (!MayIUseCode("DUY" + xFilial("DUY")+cCodGRUP) )//verifica se esta na memoria, sendo usado
				cCodGRUP := Soma1(cCodGRUP)  //      busca o proximo numero disponivel 
			Enddo

			Aadd(aCab,{"DUY_EST"	,Padr(UPPER(cTmpUF), TamSx3("DUY_EST")[1] )		,NIL})
			Aadd(aCab,{"DUY_GRPVEN"	,cCodGRUP										,NIL})
			Aadd(aCab,{"DUY_DESCRI"	,Padr(CC2->CC2_MUN, TamSx3("DUY_DESCRI")[1] )	,NIL})
			Aadd(aCab,{"DUY_CODMUN"	,cTmpMun										,NIL})
			Aadd(aCab,{"DUY_GRPSUP"	,cTmpUF											,NIL})
			Aadd(aCab,{"DUY_FILDES"	,""												,NIL})
			Aadd(aCab,{"DUY_CDRCOL"	,""												,NIL})
			Aadd(aCab,{"DUY_REGCOL"	,""												,NIL})
			Aadd(aCab,{"DUY_CATREG"	,"1"											,NIL})
			Aadd(aCab,{"DUY_CDRTAX"	,""												,NIL})
			Aadd(aCab,{"DUY_CATGRP"	,"3"											,NIL})
			Aadd(aCab,{"DUY_REGISE"	,"2"											,NIL})
			Aadd(aCab,{"DUY_ALQISS"	,0												,NIL}) 

			lMsErroAuto := .F.
			MsExecAuto({|x,y,z|Tmsa115(x,y,z)},aCab,3)

			If lMsErroAuto
				if (!isblind()) // COM INTERFACE GRÁFICA
					MostraErro() // TELA
				else // EM ESTADO DE JOB
					//Mensagem de erro do execauto
					cArqLog   	:= GetNextAlias()+".log"
					cMsgErro 	:=  MostraErro(cLogPath,cArqLog)

					//Apaga o arquivo de LOG.
					if file(cLogPath+"\"+cArqLog)
						FErase(cLogPath+"\"+cArqLog)
					endif
				endif
				lRet := .F.
			Else
				lRet := .T.
			EndIf

		EndIF
	EndIF

	Restarea(aAreaAtu)

Return lRet


/*/{Protheus.doc} MsgHelp
Função para Criar Tela de Help Reduzida
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 12/06/2020
@param cRotina, character, param_description
@param cTexto, character, param_description
@param cSolucao, character, param_description
@return return_type, return_description
/*/
Static Function MsgHelp(cRotina, cTexto, cSolucao)
	Default cRotina  := Alltrim(ProcName(1))
	Default cTexto	 := ""
	Default cSolucao := ""

	If Substr(UPPER(cRotina),1,2) == "U_"
		cRotina := Substr(UPPER(cRotina),3,Len(cRotina))
	EndIF

	IF Empty(cSolucao)
		Help(,, 'Help ['+Alltrim(cRotina)+']',, Alltrim(cTexto),1,0)
	Else
		Help(,, 'Help ['+Alltrim(cRotina)+']',, Alltrim(cTexto), 1, 0, NIL, NIL, NIL, NIL, NIL, {cSolucao})
	EndIF

Return .T.

// 29/12/2021 - Ticket 13209115
/*/{Protheus.doc} VldCGC
Função para validar se a transportadora é propria ou terceiro
@type function
@version V.12.1.27
@author Reinaldo Dias
@since 12/06/2020
@param cTransCGC, character, param_description
@return return_type, return_description
/*/
Static Function VldCGC(cTransCGC)  
	Local lRetCGC := .F. 
	Local aListCGC := FWLoadSM0() 
	Local nFaz	   := 0

	For nFaz := 1 To Len(aListCGC)
		IF Alltrim(cTransCGC) == Alltrim(aListCGC[nFaz, 18])
			lRetCGC := .T.
			Exit
		EndIF
	Next nFaz

Return lRetCGC
// 29/12/2021 - Ticket 13209115

/*/{Protheus.doc} LocDAK

Localiza DAK

@type function
@version 
@author fabio.cazarini
@since 07/07/2020
@param cCarga, character, param_description
@param cSeqCar, character, param_description
@return return_type, return_description
/*/
Static Function LocDAK(cCarga, cSeqCar)

    Local lRet      := .F.
    Local cQuery    := ""
    Local cAliasQry := ""

    cQuery := "SELECT DAK.R_E_C_N_O_ RECNODAK"
    cQuery += "  FROM " + RetSqlName("DAK") + " DAK "
    cQuery += " WHERE DAK.DAK_FILIAL = '" + FwXFilial("DAK") + "' "
    cQuery += "   AND DAK.DAK_COD = '" + AvKey(cCarga,"DAK_COD") + "' "
    cQuery += "   AND DAK.DAK_SEQCAR = '" + AvKey(cSeqCar,"DAK_SEQCAR") + "' "
    cQuery += "   AND DAK.D_E_L_E_T_ = ' ' "

    cQuery      := ChangeQuery(cQuery)
    cAliasQry   := MPSysOpenQuery(cQuery)

    (cAliasQry)->( DbGoTop() )
    If (cAliasQry)->( !EoF() )
        lRet := .T.
        DAK->( DbGoTo( (cAliasQry)->RECNODAK ) )
    Endif
    (cAliasQry)->( DbCloseArea() )

Return lRet

//Função para disparar mensagem com detalhes.
//cTitulo - Titulo da Tela de Abertura
//cMensagem - Mensagem que será apresentada na tela sem o detalhe
//cDetalhe - Mensagem que será apresentada ao clicar em detalhe, geralmente será um bloco de texto.
Static Function MsgDtlhe(cTitulo, cMensagem, cDetalhe)
	Local oDlgII				:= Nil
	Local oFntTit				:= Nil
	Local oFntMsg				:= Nil
	Local oBmp					:= Nil
	Local oMsgDet				:= Nil
	Local lTelaDetalhe			:= .F.
	Local lExibeBotaoDetalhe	:= .T.

	Default cTitulo		:= 'Mensagem de Integração' 
	Default cMensagem 	:= ''
	Default cDetalhe 	:= ''

	If Empty(cDetalhe)
		lExibeBotaoDetalhe := .F.
	EndIf

	DEFINE MSDIALOG oDlgII TITLE cTitulo FROM 0,0 TO 130,600 PIXEL 

	DEFINE FONT oFntTit NAME "Arial"  SIZE 6,16	BOLD
	DEFINE FONT oFntMsg NAME "Arial"  SIZE 5,15

	@ 0,0  BITMAP oBmp RESNAME "LOGIN" oF oDlgII SIZE 100,600 NOBORDER WHEN .F. PIXEL 
	@05,60 TO 45,300 PROMPT 'Informação' PIXEL
	@13,62 GET cMensagem FONT oFntMsg MULTILINE NOBORDER READONLY HSCROLL SIZE 236,30 PIXEL

	@50,200 BUTTON 'OK' PIXEL ACTION oDlgII:End() // "OK"

	If lExibeBotaoDetalhe
		@50,230 BUTTON 'Detalhes' PIXEL ACTION If(	!lTelaDetalhe,;  // "Detalhes"
		(oDlgII:ReadClientCoors(.T.),oDlgII:Move(oDlgII:nTop,oDlgII:nLeft,oDlgII:nWidth,oDlgII:nHeight+165,,.T.),lTelaDetalhe:=.T.),;
		(oDlgII:ReadClientCoors(.T.),oDlgII:Move(oDlgII:nTop,oDlgII:nLeft,oDlgII:nWidth,oDlgII:nHeight-165,,.T.),lTelaDetalhe:=.F.))		
		@ 67,60 TO 140,300 PROMPT "Detalhes da informação:" PIXEL
		@ 75,62 GET oMsgDet VAR cDetalhe FONT oFntMsg MULTILINE NOBORDER READONLY HSCROLL SIZE 236,63 PIXEL
	EndIf

	oDlgII:lEscClose	:= .F. //Nao permite sair ao se pressionar a tecla ESC.
	oDlgII:lCentered	:= .T.
	oDlgII:Activate(,,,.T.)
	//ACTIVATE MSDIALOG oDlgII CENTERED

Return .T.

Static Function fDestEx(nRECNO_F2)
	Local SQL := ""
	Local cCDRDES := ""
	Local cAliasQry := ""

	//Busca o destino nos dados logísticos do pedido
	SQL := "SELECT DUY.DUY_GRPVEN"
	SQL += "  FROM " + RetSqlName("PBF") + " PBF"
	SQL += "  JOIN " + RetSqlName("SC5") + " SC5 ON SC5.C5_FILIAL = PBF.PBF_FILIAL AND SC5.C5_PEDEXP = PBF.PBF_PEDEXP AND SC5.D_E_L_E_T_ = ' '"
	SQL += "  JOIN " + RetSqlName("SD2") + " SD2 ON SD2.D2_FILIAL = PBF.PBF_FILIAL AND SD2.D2_PEDIDO = SC5.C5_NUM AND SD2.D_E_L_E_T_ = ' '"
	SQL += "  JOIN " + RetSqlName("SF2") + " SF2 ON SF2.F2_FILIAL = PBF.PBF_FILIAL AND SF2.F2_DOC = SD2.D2_DOC AND SF2.F2_SERIE = SD2.D2_SERIE AND SF2.D_E_L_E_T_ = ' '"
	SQL += "  JOIN " + RetSqlName("SA1") + " SA1 ON SA1.A1_FILIAL = '     ' AND SA1.A1_COD = SF2.F2_CLIENTE AND SA1.A1_LOJA = SF2.F2_LOJA AND SA1.D_E_L_E_T_ = ' '"
	SQL += "  JOIN " + RetSqlName("SYR") + " SYR ON SYR.YR_FILIAL = '01   ' AND SYR.YR_DESTINO = PBF.PBF_DESTIN AND SYR.YR_ORIGEM = PBF.PBF_ORIGEM AND SYR.D_E_L_E_T_ = ' '"
	SQL += "  JOIN " + RetSqlName("ZZG") + " ZZG ON ZZG.ZZG_FILIAL = '     ' AND ZZG.ZZG_MUNDL = PBF.PBF_DESTIN AND ZZG.D_E_L_E_T_ = ' ' "
	SQL += "  JOIN " + RetSqlName("CC2") + " CC2 ON CC2.CC2_FILIAL = '     ' AND CC2.CC2_CODMUN = ZZG.ZZG_CODMUN AND CC2.CC2_EST = ZZG.ZZG_EST AND CC2.D_E_L_E_T_ = ' '"
	SQL += "  JOIN " + RetSqlName("DUY") + " DUY ON DUY.DUY_FILIAL = '01   ' AND DUY.DUY_EST = 'PR' AND DUY.DUY_CODMUN = CC2.CC2_CODMUN AND DUY.D_E_L_E_T_ = ' '"
	SQL += " WHERE PBF.D_E_L_E_T_ = ' '"
	SQL += "   AND PBF.PBF_MODAL = '7-Rodoviaria   '"
	SQL += "   AND SF2.R_E_C_N_O_ = '" + STR(nRECNO_F2) + "'"

	cAliasQry := MPSysOpenQuery(SQL)

	(cAliasQry)->( DbGoTop() )

	If (cAliasQry)->( !EoF() )
		cCDRDES := (cAliasQry)->DUY_GRPVEN
	Endif

	(cAliasQry)->(DbCloseArea())

	SA1->( Reclock("SA1",.F.))
	SA1->A1_CDRDES := cCDRDES
	SA1->( MsUnlock())
Return .T.

Static Function fCarregaTG(aCargaDAK)
	DBSelectArea("SA1")
	DBSetOrder(1) //A1_FILIAL+A1_COD+A1_LOJA
	DBseek(xFilial("SA1")+aCargaDAK[1,3]+aCargaDAK[1,4])

	//Verifica se é cliente do exterior
	If SA1->A1_EST = 'EX'
		cCliGen := Alltrim(SuperGetmv("MV_CLIEX",.F.,"000001"))
		cCodNeg := SuperGetmv("FS_C040044",.F.,"05")
	EndIf
Return .T.


/*/{Protheus.doc} fCriaDTA
Função para criar a Tabela DTA - Carregamento
@type function
@version V.12.1.33
@author Max Nascimento
@since 25/01/2023
@param cDTCDoc, character, param_description
@param cDTCSerie, character, param_description
@param cCodViag, character, param_description
@param cTmpVol, character, param_description
@param cTmpVeic, character, param_description
@param cDTCFrete, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDTA(cDTCDoc, cDTCSerie, cCodViag, cTmpVol, cTmpVeic, cDTCFrete)
	Local aAreaAtu 	:= getarea()
	Local cSeekDTA	:= ""
	DTA->(DbSetOrder(1)) //DTA_FILIAL+DTA_FILDOC+DTA_DOC+DTA_SERIE+DTA_FILORI+DTA_VIAGEM
	If	DTA->(dbSeek(cSeekDTA:= xFilial('DTA')+cFilAnt+cDTCDoc+cDTCSerie+cFilAnt+cCodViag))
		While DTA->(!Eof() .And. DTA_FILIAL+DTA_FILDOC+DTA_DOC+DTA_SERIE+DTA_FILORI+DTA_VIAGEM == cSeekDTA)
			Reclock("DTA",.F.)
				DTA_FILIAL := xFilial("DTA")	
                DTA_FILORI := cFilAnt
                DTA_VIAGEM := cCodViag  	
                DTA_FILDOC := cFilAnt	
                DTA_DOC	   := cDTCDoc
                DTA_SERIE  := cDTCSerie
                DTA_QTDVOL := cTmpVol			
                DTA_SERTMS := "3"		
                DTA_TIPTRA := "1"
                DTA_FILATU := cFilAnt	
                DTA_FILDCA := cFilAnt		
                DTA_TIPCAR := "2"
                DTA_CODVEI := cTmpVeic		
                DTA_VALFRE := cDTCFrete
                DTA_ORIGEM := "1"	
			DTA->( MsUnLock() )
			DTA->(dbSkip())
		EndDo
	Else
		Reclock("DTA",.T.)
			DTA_FILIAL := xFilial("DTA")	
            DTA_FILORI := cFilAnt
            DTA_VIAGEM := cCodViag  	
            DTA_FILDOC := cFilAnt	
            DTA_DOC	   := cDTCDoc
            DTA_SERIE  := cDTCSerie
            DTA_QTDVOL := cTmpVol			
            DTA_SERTMS := "3"		
            DTA_TIPTRA := "1"
            DTA_FILATU := cFilAnt	
            DTA_FILDCA := cFilAnt		
            DTA_TIPCAR := "2"
            DTA_CODVEI := cTmpVeic		
            DTA_VALFRE := cDTCFrete
            DTA_ORIGEM := "1"	
		DTA->(MsUnlock())
	EndIF
	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDM3
Função para criar a Tabela DM3 - Documentos da Viagem Mod.3
@version V.12.1.33
@author Max Nascimento
@since 25/01/2023
@param cDTCDoc, character, param_description
@param cDTCSerie, character, param_description
@param cCodViag, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDM3(cDTCDoc, cDTCSerie, cCodViag)
	Local aAreaAtu 	:= getarea()
	Local cSeekDM3	:= ""
	DM3->(DbSetOrder(1)) //DM3_FILIAL + DM3_FILDOC + DM3_DOC + DM3_SERIE + DM3_FILORI + DM3_VIAGEM
	If	DM3->(dbSeek(cSeekDM3:= xFilial('DM3')+cFilAnt+cDTCDoc+cDTCSerie+cFilAnt+cCodViag))
		While DM3->(!Eof() .And. DM3_FILIAL+DM3_FILDOC+DM3_DOC+DM3_SERIE+DM3_FILORI+DM3_VIAGEM == cSeekDM3)
			Reclock("DM3",.F.)
				DM3_FILIAL := xFilial("DM3")	
                DM3_FILORI := cFilAnt
                DM3_VIAGEM := cCodViag  	
                DM3_SEQUEN := "001"
                DM3_FILDOC := cFilAnt	
                DM3_DOC	   := cDTCDoc
                DM3_SERIE  := cDTCSerie	
			DM3->( MsUnLock() )
			DM3->(dbSkip())
		EndDo
	Else
		Reclock("DM3",.T.)
			DM3_FILIAL := xFilial("DM3")	
            DM3_FILORI := cFilAnt
            DM3_VIAGEM := cCodViag  	
            DM3_SEQUEN := "001"
            DM3_FILDOC := cFilAnt	
            DM3_DOC	   := cDTCDoc
            DM3_SERIE  := cDTCSerie	
		DM3->(MsUnlock())
	EndIF
	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDM4
Função para criar a Tabela DM4 - Planejamento da Viagem Mod.3
@version V.12.1.33
@author Max Nascimento
@since 25/01/2023
@param cCodViag, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDM4(cCodViag)
	Local aAreaAtu 	:= getarea()
	Local cSeekDM4	:= ""
	DM4->(DbSetOrder(1)) //DM4_FILIAL + DM4_FILORI + DM4_VIAGEM
	If	DM4->(dbSeek(cSeekDM4:= xFilial('DM4')+cFilAnt+cCodViag))
		While DM4->(!Eof() .And. DM4_FILIAL+DM4_FILORI+DM4_VIAGEM == cSeekDM4)
			Reclock("DM4",.F.)
				DM4_FILIAL := xFilial("DM4")	
                DM4_FILORI := cFilAnt
                DM4_VIAGEM := cCodViag  		
			DM4->( MsUnLock() )
			DM4->(dbSkip())
		EndDo
	Else
		Reclock("DM4",.T.)
			DM4_FILIAL := xFilial("DM4")	
            DM4_FILORI := cFilAnt
            DM4_VIAGEM := cCodViag  	
		DM4->(MsUnlock())
	EndIF
	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDM6
Função para criar a Tabela DM6 - Viagem Carregada 
@type function
@version V.12.1.33
@author Max Nascimento
@since 25/01/2023
@param cCodViag, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDM6(cCodViag)
	Local aAreaAtu 	:= getarea()
	Local cSeekDM6	:= ""
	Local dData 	:= date()
	Local cHora 	:= time()
	DM6->(DbSetOrder(1)) //DM6_FILIAL+DM6_FILORI+DM6_VIAGEM
	If	DM6->(dbSeek(cSeekDM6:= xFilial('DM6')+cFilAnt+cCodViag))
		While DM6->(!Eof() .And. DM6_FILIAL+DM6_FILORI+DM6_VIAGEM == cSeekDM6)
			Reclock("DM6",.F.)
				DM6_FILIAL := xFilial("DM6")	
                DM6_FILORI := cFilAnt
                DM6_VIAGEM := cCodViag  
				DM6_DATCAR := dData
				DM6_HORCAR := cHora
			DM6->( MsUnLock() )
			DM6->(dbSkip())
		EndDo
	Else
		Reclock("DM6",.T.)
			DM6_FILIAL := xFilial("DM6")	
            DM6_FILORI := cFilAnt
            DM6_VIAGEM := cCodViag  
			DM6_DATCAR := dData
			DM6_HORCAR := cHora
		DM6->(MsUnlock())
	EndIF
	Restarea(aAreaAtu)

Return .T.


/*/{Protheus.doc} fCriaDM7
Função para Criar Tabela DM7 (Veiculos Carregados)
@type function
@version V.12.1.33
@author Max Nascimento
@since 25/01/2023
@param cTmpVge, character, param_description
@param cTmpVeic, character, param_description
@return return_type, return_description
/*/
Static Function fCriaDM7(cTmpVge, cTmpVeic, cVeic02, cVeic03)
	Local aAreaAtu 	:= getarea()

	DM7->(dbSetOrder(1)) //DM7_FILIAL + DM7_FILORI + DM7_VIAGEM + DM7_ITEDTR
	If DM7->(MsSeek(FwxFilial('DM7')+cFilAnt+cTmpVge))
		Reclock("DM7",.F.)
	Else
		Reclock("DM7",.T.)
	EndIF
	DM7->DM7_FILIAL := xFilial("DM7")
	DM7->DM7_FILORI := cFilAnt
	DM7->DM7_VIAGEM := cTmpVge
	DM7->DM7_ITEDTR := "01"
	DM7->DM7_CODVEI := cTmpVeic
	If !EmpTy(cVeic02)
		DM7->DM7_CODRB1	:= cVeic02
	EndIf	
	If !Empty(cVeic03)
		DM7->DM7_CODRB2	:= cVeic03
	EndIf	

	DM7->(MsUnlock())

	Restarea(aAreaAtu)

Return .T.


