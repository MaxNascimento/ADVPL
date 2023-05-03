#Include 'Protheus.ch'
#Include "VKey.ch"

/*/{Protheus.doc} G0517303
//TODO Tela de solicitação da aprovação de ajuste de estoque.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}
@param nTipo, numeric, Tipo de operação realizada: Inclusão, Atualização, Exclusão ou Visualização 
@param cINNumero, characters, Número sequencial da solicitação da aprovação de ajuste de estoque
@type function
/*/
User Function G0517303(nTipo,cINNumero,cINCod)
	Local nOpc 			:= GD_INSERT+GD_DELETE+GD_UPDATE
	Local lReadOnly		:= .F.
	Local aSizeCol		:= {}
	Local aCamposAlt	:= {}
	Private cVersao		:= "1.0"
	Private cDtUltAlt	:= "10/12/2019"
	Private aCoZ38 		:= {}
	Private aHeadZ38 	:= {}
	Private noBrw1  	:= 0 
	Private cCod		:= ""
	Private cCC        := Space(TamSx3("Z38_CC")[1])
	Private cTM        := Space(TamSx3("Z38_TM")[1])
	Private dData      := Date()
	Private cNumero		:= ""
	Private cStatus   	:= "1"
	Private oGreen		:= LoadBitmap( GetResources(), "BR_VERDE")
	Private oRed		:= LoadBitmap( GetResources(), "BR_VERMELHO")
	Private oBlue		:= LoadBitmap( GetResources(), "BR_AZUL")	
	Default cINNumero	:= GetSXENUM("Z38","Z38_NUMERO")

	SetPrvt("oDlg1","oGrp1","oGet1","oGet2","oGet3","oGet4","oCBox1","oGrp2","oBrw1","oBtn1","oBtn2")
	
	If FindFunction("U_G051733V")
		SetKey(K_CTRL_F12, {||U_G051733V()})
	Else
		SetKey(K_CTRL_F12, Nil)
	EndIf
	
	If nTipo == 2 .Or. nTipo == 5
		nOpc := 0
		lReadOnly := .T.
	EndIF
	
	cNumero := cINNumero 	
	cCod	:= cINCod
	
	oDlg1      := MSDialog():New( 092,232,490,1088,"Solicitação da aprovação de ajuste de estoque"+IIF(ntipo == 2," [Modo Visualização]",IIF(nTipo == 5, " [Modo de Exclusão]","")),,,.F.,,,,,,.T.,,,.T. )
	oGrp1      := TGroup():New( 000,004,036,426,"Solicitação da aprovação:",oDlg1,CLR_BLACK,CLR_WHITE,.T.,.F. )
	oGet1      := TGet():New( 014,012,{|u| If(PCount()>0,cNumero:=u,cNumero)},oGrp1,040,008,'',					 ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","cNumero",,,,,,,"Número:",1)
	oGet2      := TGet():New( 014,068,{|u| If(PCount()>0,cTM:=u,cTM)}		  ,oGrp1,028,008,'',{||Valida("SF5",cTM)},CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lReadOnly,.F.,"SF5","cTM",,,,,,,"Tipo Movto:",1)	
	oGet4      := TGet():New( 014,112,{|u| If(PCount()>0,cCC:=u,cCC)}		  ,oGrp1,040,008,'',{||Valida("CTT",cCC)},CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lReadOnly,.F.,"CTT","cCC",,,,,,,"Centro Custo:",1)
	oGet3      := TGet():New( 014,164,{|u| If(PCount()>0,dData:=u,dData)}	  ,oGrp1,048,008,'',					 ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,lReadOnly,.F.,"","dData",,,,,,,"Data:",1)
	oGrp2      := TGroup():New( 036,004,183,426,"Itens:",oDlg1,CLR_BLACK,CLR_WHITE,.T.,.F. )
	
	MHoBrw1()
	MCoBrw1()
	If nTipo <> 3
		BuscaZ38(cNumero, cCod)
	EndIf
	aSizeCol	:= {{"Z38_COD",30},{"Z38_UM",30},{"Z38_QUANT",35},{"Z38_LOCAL",35},{"Z38_LTCTL",35},{"Z38_LOCALI",35},{"Z38_OBS",60},{"Z38_DOC",30},{"Z38_XSUNME",30}}
	aCamposAlt	:=  {"Z38_COD"    , "Z38_UM"    , "Z38_QUANT"    , "Z38_LOCAL"     , "Z38_LTCTL"    , "Z38_LOCALI"    , "Z38_OBS"    , "Z38_DOC","Z38_XSUNME"}
	oBrw1		:= MsNewGetDados():New(044,008,176,424,nOpc,'U_G0517305(oBrw1:aCols,oBrw1:aCols[N,1],N,aHeadZ38)','AllwaysTrue()','',aCamposAlt,1,99,'AllwaysTrue()','','u_G0517306()',oGrp2,aHeadZ38,aCoZ38,,,aSizeCol )
	
	oBtn1		:= TButton():New( 185,146,IIF(nTipo==5,"Excluir","Confirmar"),oDlg1,{||IIF(nTipo == 2,MsgAlert("Não é permitido gravar em modo de visualização.","[G0517302] Aviso"),IIF(nTipo ==5,Processa({||Excluir()},"Excluindo...."),Processa({||Gravar()},"Gravando....")))},077,012,,,,.T.,,"",,,,.F. )
	oBtn2		:= TButton():New( 185,228,"Sair",oDlg1,{||RollbackSx8(), oDlg1:End()},037,012,,,,.T.,,"",,,,.F. )
	oDlg1:Activate(,,,.T.)
Return .T.

/*/{Protheus.doc} Gravar
//TODO Insere ou atualiza uma solicitação da aprovação de ajuste de estoque.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function Gravar()
	Local i			:= 1
	Local z			:= 1
	Local lAchou 	:= .F.
	Local lFinaliz	:= .T.
	Local lRejeit	:= .T.
	Local lResp		:= .F.
	Local cDescItem	:= ""
    Local  cName:=UsrRetName(RetCodUsr())
	
	If Empty(cTM)
		MsgAlert("Código do Tipo de Movimento Obrigatório.","[G0517303] Validação")
		Return .F.
	EndIf
	
	If Empty(dData)
		MsgAlert("Data do Movimento é Obrigatório.","[G0517303] Validação")
		Return .F.
	EndIf
	
	For i:=1 To Len(oBrw1:aCols)
		If Empty(oBrw1:aCols[i,nPos("Z38_COD")])
			MsgAlert("Código do Produto Obrigatório.","[G0517303] Validação")
			Return .F.
		EndIf	
		
		If oBrw1:aCols[i,nPos("Z38_QUANT")] == 0
			MsgAlert("Quantidade tem que ser maior que zero.", "[G0517303] Validação")
			Return .F.
		EndIf
		
		If Empty(oBrw1:aCols[i,nPos("Z38_LOCAL")])
			MsgAlert("Código do Armazem Obrigatório.", "[G0513703] Validação")
			Return .F.
		EndIf
	Next i 
	
	DbSelectArea("Z38")
	DbSetOrder(1)
	For i:=1 To Len(oBrw1:aCols)
		lFinaliz := Finalizada(cNumero, oBrw1:aCols[i,nPos("Z38_COD")]) 
		If lFinaliz
			If oBrw1:aCols[i,Len(aHeadZ38)+1]
				oBrw1:aCols[i,Len(aHeadZ38)+1] := .F.
			EndIf
			MsgAlert("Registro com status 'Finalizado' não pode ser alterado.","[G0517303] Validação")
			Return .F.
		Else
			lFinaliz := Finalizada(cNumero, oBrw1:aCols[i,nPos("Z38_COD")]) 
			If !oBrw1:aCols[i,Len(aHeadZ38)+1]  .And. !lFinaliz 
				If !DbSeek(xFilial("Z38")+avKey(cNumero,"Z38_NUMERO")+oBrw1:aCols[i,nPos("Z38_COD")])
					RecLock("Z38",.T.)
						Z38->Z38_FILIAL := xFilial("Z38")
						Z38->Z38_NUMERO	:= cNumero
						Z38->Z38_TM		:= cTM
						Z38->Z38_DATA	:= dData
						Z38->Z38_CC		:= cCC
						Z38->Z38_STATUS := "1"
						Z38->Z38_COD	:= oBrw1:aCols[i,nPos("Z38_COD")]
						Z38->Z38_UM		:= oBrw1:aCols[i,nPos("Z38_UM")]
						Z38->Z38_QUANT	:= oBrw1:aCols[i,nPos("Z38_QUANT")]
						Z38->Z38_LOCAL	:= oBrw1:aCols[i,nPos("Z38_LOCAL")]
						Z38->Z38_XSUNME := oBrw1:aCols[i,nPos("Z38_XSUNME")]
						Z38->Z38_XFTCON	:= oBrw1:aCols[i,nPos("Z38_XFTCON")]
						Z38->Z38_LTCTL	:= oBrw1:aCols[i,nPos("Z38_LTCTL")]
						Z38->Z38_LOCALI	:= oBrw1:aCols[i,nPos("Z38_LOCALI")]
						Z38->Z38_OBS	:= oBrw1:aCols[i,nPos("Z38_OBS")]
						Z38->Z38_DOC	:= oBrw1:aCols[i,nPos("Z38_DOC")]
						Z38->Z38_VLRAJ	:= oBrw1:aCols[i,nPos("Z38_VLRAJ")]
						Z38->Z38_USUAR	:= cName
					Z38->(MsUnlock())
				Else
					lRejeit	:= Rejeitada(cNumero, oBrw1:aCols[i,nPos("Z38_COD")])
					
					If lRejeit
						cDescItem	:= Alltrim(Posicione("SB1",1,xFilial("SB1")+ AvKey(oBrw1:aCols[i,nPos("Z38_COD")],"Z38_COD") ,"B1_DESC"))
						cDescItem	:= oBrw1:aCols[i,nPos("Z38_COD")] + "-"+ cDescItem
						If MsgYesNo("O item: " + cDescItem + " está rejeitado, deseja alterar o status para em aprovação?", "[G0517307] Aviso")
							lResp	:= .T.
						EndIf
					EndIf
					
					If DbSeek(xFilial("Z38")+AvKey(cNumero,"Z38_NUMERO")+AvKey(oBrw1:aCols[i,nPos("Z38_COD")],"Z38_COD"))
						RecLock("Z38",.F.)
							Z38->Z38_TM		:= cTM
							Z38->Z38_DATA	:= dData
							Z38->Z38_CC		:= cCC
							Z38->Z38_STATUS := IIf(lResp, "1", IIf(lRejeit, "3", "1"))
							Z38->Z38_COD	:= oBrw1:aCols[i,nPos("Z38_COD")]
							Z38->Z38_UM		:= oBrw1:aCols[i,nPos("Z38_UM")]
							Z38->Z38_QUANT	:= oBrw1:aCols[i,nPos("Z38_QUANT")]
							Z38->Z38_LOCAL	:= oBrw1:aCols[i,nPos("Z38_LOCAL")]
							Z38->Z38_XSUNME := oBrw1:aCols[i,nPos("Z38_XSUNME")]
							Z38->Z38_XFTCON	:= oBrw1:aCols[i,nPos("Z38_XFTCON")]
							Z38->Z38_LTCTL	:= oBrw1:aCols[i,nPos("Z38_LTCTL")]
							Z38->Z38_LOCALI	:= oBrw1:aCols[i,nPos("Z38_LOCALI")]
							Z38->Z38_OBS	:= oBrw1:aCols[i,nPos("Z38_OBS")]
							Z38->Z38_DOC	:= oBrw1:aCols[i,nPos("Z38_DOC")]
							Z38->Z38_VLRAJ	:= oBrw1:aCols[i,nPos("Z38_VLRAJ")]
							Z38->Z38_USUAR	:= cName
						Z38->(MsUnlock())
					EndIf
				EndIf
			Else
				If DbSeek(xFilial("Z38")+avKey(cNumero,"Z38_NUMERO")+oBrw1:aCols[i,nPos("Z38_COD")])
					If !Finalizada(cNumero, oBrw1:aCols[i,nPos("Z38_COD")])
						RecLock("Z38", .F.)
							Z38->(DbDelete())
						Z38->(MsUnlock())
					EndIf
				EndIf
			EndIf
		EndIf
	Next i
	
	ConfirmSx8()
	MsgInfo("Registro salvo com sucesso.","[G0517303] Sucesso")
	oDlg1:End()
Return .T.

/*/{Protheus.doc} Excluir
//TODO Excluiu uma solicitação da aprovação de ajuste de estoque.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function Excluir()
	DbSelectArea("Z38")
	DbSetOrder(1)
	If DbSeek(xFilial("Z38")+avKey(cNumero,"Z38_NUMERO")+avKey(cCod,"Z38_COD"))
		If ValFinaliz(cNumero, cCod)
			MsgAlert("Registro com status 'Finalizado' não pode ser excluído.","[G0517303] Aviso")
			Return .F.
		EndIf
		
		RecLock("Z38", .F.)
			Z38->(DbDelete())
		Z38->(MsUnlock())
			
		MsgAlert("Registro excluido com sucesso!","[G0517303] Aviso")
	Else
		MsgAlert("Erro ao Excluir o cadastro.","[G0517303] Aviso")
	EndIf
	oDlg1:End()
Return .T.

/*/{Protheus.doc} BuscaZ38
//TODO Popula os dados da solicitação da aprovação de ajuste de estoque.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}
@param cINNum, characters, Identificador da solicitação da aprovação de ajuste de estoque
@type function
/*/
Static Function BuscaZ38(cINNum, cINProd)
	Local cSql	:= ""
	Local nQtde	:= 1
	Local nI
	
	cSql	:= " SELECT Z38_FILIAL "
    cSql	+= "       ,Z38_NUMERO "
    cSql	+= "       ,Z38_TM "
    cSql	+= "       ,Z38_DATA "
    cSql	+= "       ,Z38_CC "
    cSql	+= "       ,Z38_STATUS "
    cSql	+= "       ,Z38_COD "
    cSql	+= "       ,Z38_UM "
    cSql	+= "       ,Z38_QUANT "
    cSql	+= "       ,Z38_LOCAL "
    cSql	+= "       ,Z38_LTCTL "
    cSql	+= "       ,Z38_LOCALI "
    cSql	+= "       ,Z38_OBS "
    cSql	+= "       ,Z38_DOC "
    cSql	+= "       ,Z38_VLRAJ "
	cSql	+= "       ,Z38_XSUNME "
	cSql	+= "       ,Z38_XFTCON "
    cSql	+= "  FROM "+RetSqlName("Z38")+" Z38 "
    cSql	+= " WHERE Z38.D_E_L_E_T_ = ' ' "
    cSql	+= "   AND Z38.Z38_FILIAL = '"+xFilial("Z38")+"' "
    cSql	+= "   AND Z38.Z38_NUMERO = '"+cINNum+"' "
    cSql	+= "   AND Z38.Z38_COD    = '"+cINProd+"' "    
    cSql	+= " ORDER BY Z38_NUMERO,Z38_COD "
	DbUseArea(.T.,'TOPCONN',TcGenQry(,,cSql),"TMPZ38",.F.,.T.)
	DbSelectArea("TMPZ38")
	TMPZ38->(DbGoTop())
	
	While !TMPZ38->(Eof())
		cCC		:= TMPZ38->Z38_CC
		cTM		:= TMPZ38->Z38_TM
		dData	:= StoD(TMPZ38->Z38_DATA)
		cNumero	:= TMPZ38->Z38_NUMERO
		
		If nQtde > 1
			Aadd(aCoZ38,Array(noBrw1+1))
		EndIf
		For nI := 1 To noBrw1
			If nI == 1 
				If TMPZ38->Z38_STATUS == "1"
					aCoZ38[nQtde][1] := oGreen
				ElseIf TMPZ38->Z38_STATUS == "2"
					aCoZ38[nQtde][1] := oBlue
				ElseIf TMPZ38->Z38_STATUS == "3"
					aCoZ38[nQtde][1] := oRed
				EndIf
			Else
			 	If !(aHeadZ38[nI][1] $ "Z38_FILIAL/Z38_NUMERO/Z38_TM/Z38_DATA/Z38_CC/Z38_STATUS/Z38_JUSTIF/Z38_USUAR")  /*/*/
			 		aCoZ38[nQtde][nI] := CriaVar(aHeadZ38[nI][2])
			 		aCoZ38[nQtde][nI] := &("TMPZ38->"+aHeadZ38[nI][2])
				EndIf
			EndIf
		Next nI
		
		aCoZ38[1][noBrw1+1] := .F.
	
		nQtde++
		TMPZ38->(DbSkip())
	EndDo
	TMPZ38->(DbCloseArea())
Return .T.

/*/{Protheus.doc} ValFinaliz
//TODO Valida se os itens da solicitação da aprovação de ajuste de estoque estão com a situação Finalizado.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}
@param cINNum, characters, Identificador da solicitação da aprovação de ajuste de estoque
@type function
/*/
Static Function ValFinaliz(cINNum, cINProd)
	Local cSql	:= ""
	Local nQtde	:= 0
	
	cSql	:= " SELECT COUNT(1) Qtde"
    cSql	+= "  FROM "+RetSqlName("Z38")+" Z38 "
    cSql	+= " WHERE Z38.D_E_L_E_T_ = ' ' "
    cSql	+= "   AND Z38.Z38_FILIAL = '"+xFilial("Z38")+"' "
    cSql	+= "   AND Z38.Z38_NUMERO = '"+cINNum+"' "
    cSql	+= "   AND Z38.Z38_COD    = '"+cINProd+"' "    
    cSql	+= "   AND Z38.Z38_STATUS = '2' "
	DbUseArea(.T.,'TOPCONN',TcGenQry(,,cSql),"TMPZ38",.F.,.T.)
	DbSelectArea("TMPZ38")
	TMPZ38->(DbGoTop())
	
	While !TMPZ38->(Eof())
		nQtde	:= TMPZ38->QTDE		
		If nQtde <> 0
			lRet :=  .T.
		ElseIf nQtde == 0 
			lRet := .F.
		EndIf
		TMPZ38->(DbSkip())
	EndDo
	TMPZ38->(DbCloseArea())
Return lRet

/*/{Protheus.doc} Finalizada
//TODO Busca a situação dos itens da solicitação da aprovação de ajuste de estoque.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}
@param cINNumero, characters, Identificador da solicitação da aprovação de ajuste de estoque
@param cINCod, characters, Identificador do item da solicitação da aprovação de ajuste de estoque
@type function
/*/
Static Function Finalizada(cINNumero, cINCod)
	Local lRet := .F.
	DbSelectArea("Z38")
	DbSetOrder(1)
	If DbSeek(xFilial("Z38")+avKey(cINNumero,"Z38_NUMERO")+cINCod)
		If Z38->Z38_STATUS == "2"
			lRet := .T.
		EndIf
	EndIf	
Return lRet

/*/{Protheus.doc} Rejeitada
//TODO Verifica se o item ou itens da solicitação da aprovação de ajuste de estoque estão com o status Finalizado.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}
@param cINNumero, characters, Identificador da solicitação da aprovação de ajuste de estoque
@param cINCod, characters, Identificador do item da solicitação da aprovação de ajuste de estoque
@type function
/*/
Static Function Rejeitada(cINNumero, cINCod)
	Local lRet	:= .F.
	
	DbSelectArea("Z38")
	DbSetOrder(1)
	If DbSeek(xFilial("Z38")+AvKey(cINNumero,"Z38_NUMERO")+cINCod)
		If Z38->Z38_STATUS == "3"
			lRet	:= .T.
		EndIf
	EndIf
Return lRet

/*/{Protheus.doc} Valida
//TODO Validação dos campos da solicitação da aprovação de ajuste de estoque.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}
@param cINTabela, characters, Identificador da tabela
@param cINCampo, characters, Campo a ser validado
@type function
/*/
Static Function Valida(cINTabela,cINCampo)
	Local lRet := .T.
	If !Empty(cINCampo)
		If AllTrim(cINTabela) == "CTT"
			DbSelectArea("CTT")
			DbSetOrder(1)
			If !DbSeek(xFilial("CTT")+avKey(cINCampo,"CTT_CUSTO"))
				MsgAlert("Centro de Custo não Cadastrado! Utilize a tecla de atalho F3 para selecionar um centro de custo válido.","[G0517303] Validação")
				lRet := .F.
			EndIf
		ElseIf AllTrim(cINTabela) == "SF5"
			DbSelectArea("SF5")
			DbSetOrder(1)
			If !DbSeek(xFilial("SF5")+cINCampo)
				MsgAlert("Tipo Movimento não Cadastrado! Utilize a tecla de atalho F3 para selecionar um tipo movimento válido.","[G0517303] Validação")
				lRet := .F.
			EndIf
		EndIf
	EndIf
Return lRet

/*/{Protheus.doc} MHoBrw1
//TODO Busca as informações das colunas que farão parte do cabeçalho da grid dos itens da solicitação da aprovação de ajuste de estoque.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function MHoBrw1()

Local 	aCpos := FWSX3Util():GetAllFields("Z38",.F.)
Local ni	
	Aadd(aHeadZ38,{	"St",;
	       			"COR",;
	       			"@BMP",;
	       			1,;
	       			0,;
	       			.T.,;
	       			"",;
	       			"",;
	       			"",;
	       			"R"})
	noBrw1++

	
    
    	For NI := 1 To Len(aCpos)
             If X3USO(GetSX3Cache(aCpos[nI],"X3_USADO")) .and. cNivel >= GetSX3Cache(aCpos[nI],"X3_NIVEL") .And. ;
             !(AllTrim(aCpos[nI]) $ "Z38_FILIAL/Z38_NUMERO/Z38_TM/Z38_DATA/Z38_CC/Z38_STATUS/Z38_JUSTIF/Z38_USUAR") 
              noBrw1++
	      Aadd(aHeadZ38,{;
					AllTrim(GetSX3Cache(aCpos[nI],"X3_TITULO")),; // 01 -" Titulo
					GetSX3Cache(aCpos[nI],"X3_CAMPO"),;     // 02 - Campo
					GetSX3Cache(aCpos[nI],"X3_PICTURE"),;   // 03 - Picture
					GetSX3Cache(aCpos[nI],"X3_TAMANHO"),;   // 04 - Tamanho
					GetSX3Cache(aCpos[nI],"X3_DECIMAL"),;   // 05 - Decimal
				    IIF(AllTrim(aCpos[nI]) $ "Z38_COD",;
                    "U_G0517305(,M->Z38_COD,N)","") ,;      // 06 - Valid
					'' ,;                                   // 07 - Usado
					GetSX3Cache(aCpos[nI],"X3_TIPO"),;      // 08 - Tipo
					'' ,;                                   // 09 - F3
					  "" } )                                // 10 "- Contexto
           Endif
        next ni

    /*
	DbSelectArea("SX3")
	DbSetOrder(1)
	DbSeek("Z38")
	While !SX3->(Eof()) .And. SX3->X3_ARQUIVO == "Z38"
	   If X3Uso(SX3->X3_USADO) .and. cNivel >= SX3->X3_NIVEL .And. !(AllTrim(SX3->X3_CAMPO) $ "Z38_FILIAL/Z38_NUMERO/Z38_TM/Z38_DATA/Z38_CC/Z38_STATUS/Z38_JUSTIF/Z38_USUAR") 
	      noBrw1++
	      Aadd(aHeadZ38,{Trim(X3Titulo()),;
	           SX3->X3_CAMPO,;
	           SX3->X3_PICTURE,;
	           SX3->X3_TAMANHO,;
	           SX3->X3_DECIMAL,;
	           IIF(AllTrim(SX3->X3_CAMPO) $ "Z38_COD","U_G0517305(,M->Z38_COD,N)",""),;
	           "",;
	           SX3->X3_TIPO,;
	           "",;
	           ""})
	   EndIf  
	   SX3->(DbSkip())
	EndDo
    */
Return .T.

/*/{Protheus.doc} MCoBrw1
//TODO Monta as colunas da grid de itens da solicitação da aprovação de ajuste de estoque de acordo com as configurações.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function MCoBrw1()
	Local nI
	
	Aadd(aCoZ38,Array(noBrw1+1))
	For nI := 1 To noBrw1
	   If nI == 1 
	   		aCoZ38[1][nI] := oGreen
	   Else
	   		aCoZ38[1][nI] := CriaVar(aHeadZ38[nI][2])
	   EndIf
	Next
	aCoZ38[1][noBrw1+1] := .F.
Return .T.

/*/{Protheus.doc} nPos
//TODO Retorna a posição do campo na grid.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}
@param cCampo, characters, Determina qual o campo da grid
@type function
/*/
Static Function nPos(cCampo)
	Local nPos := aScan(aHeadZ38,{|x| Alltrim(x[2]) == Alltrim(cCampo)}) 
Return nPos

/*/{Protheus.doc} G051733V
//TODO Descrição auto-gerada.
@author andre.eposhi
@since 19/11/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function G051733V()
	MsgInfo("Fonte: G0517303 " + CHR(13) + "Aprovação de ajuste do estoque " + CHR(13) + "Data Ult. Man: " + cDtUltAlt + CHR(13) + "Versão: " + cVersao, "Controle de Versão")
Return .T.
