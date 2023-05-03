#Include "TOTVS.ch"

//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0401910
//TODO Tela de carregamento Customizada.
@author wanderley.silva
@since 01/07/2019
@version 1.0
return ${return}, ${return_description}
@History 
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0401910()

	Local aPergs    := {}
	Local lRet      := .T.
	Local cContnr   := SPACE(AVSX3("PCJ_CONTNR",3))
	Local cLacre    := SPACE(AVSX3("PCJ_LACRE",3))
	Local nTara     := 0
	Local cXlcSIF   := SPACE(AVSX3("PCJ_LCSIF",3))
	Local cXlcGOV   := SPACE(AVSX3("PCJ_LCGOV",3))
	Local nXm3      := 0
	Local aRet      := {} 
	Local lTemX5    := .f.
	Local lExport   := .f.
	Local lMarit    := .f.
	Local lPBKOK 	:= .t.
	Local cMsg		:= ""
	Local lAmostra	:= .F.

	Private lContr	:= .f.
	Private lTara	:= .f.
	Private lLacre	:= .f.
	Private lLcSif	:= .f.				
	Private lM3		:= .f.

	Private lTemLcGv := .F.	

	DbSelectarea("PC8")
	PC8->(dbSetOrder(1)) //PC8_FILIAL+PC8_NUM                                                                                                                                              
	IF PC8->(dbSeek(xFilial("PC8")+SC5->C5_NUM))
		lTemX5 := .T.
		//If !Empty(aValores) .and. Len(aValores) > 5
		If !EMPTY(PC8->(PC8_CONTNR+PC8_LACRE+PC8_XLCSIF+PC8_XLCGOV))
			cContnr  := PC8->PC8_CONTNR
			nTara    := PC8->PC8_TARA  
			cLacre   := PC8->PC8_LACRE 
			cXlcSIF  := PC8->PC8_XLCSIF
			cXlcGOV  := PC8->PC8_XLCGOV
			nXm3     := PC8->PC8_XM3   
		EndIf		
	EndIf
	
	If !Empty(SC5->C5_PEDEXP) //Verifica se a NF sera referente 
		lExport	:= .t.
	    EE7->(DbSetOrder(1))
	    If EE7->(dbSeek(xFilial("EE7")+AvKey(SC5->C5_PEDEXP,"EE7_PEDIDO")))
	    	SYA->(DbSetOrder(1))
	    	If SYA->(DBSEEK(xFilial("SYA")+EE7->EE7_PAISET))
	    		lTemLcGv := IF(SYA->YA_XLCRGOV ="1",.T.,.F.)
	    		If !lTemLcGv
	    			cXlcGOV:= SPACE(AVSX3("PCJ_LCGOV",3))
	    		EndIf
	    	EndIf
	    EndIf
    EndIf
    
    if lExport
    
    	//Verifica se carga e Maritima
		DbSelectArea("SYR")
		SYQ->(DbSetOrder(1))
		If SYQ->(DbSeek(xFilial("SYR") + EE7->EE7_VIA ) )
			if Substr( SYQ->YQ_COD_DI	,1	,1 ) == "1" // Maritimo
				lMarit	:= .t.
				lContr	:= .t.
				lTara	:= .t.
				lLacre	:= .t.
				lLcSif	:= .t.				
				lM3		:= .t.
			Elseif Substr( SYQ->YQ_COD_DI	,1	,1 ) == "6" // Rodoviário
				lContr	:= .t.
				lTara	:= .t.
				lLacre	:= .t.
				lLcSif	:= .t.				
				lM3		:= .t.
			Elseif Substr( SYQ->YQ_COD_DI	,1	,1 ) == "7" // Ferriviário
				lContr	:= .t.
				lTara	:= .t.
				lLacre	:= .t.
				lLcSif	:= .t.				
				lM3		:= .t.
			Else
				lRet	:= .t.
			EndIf
		Endif
		
		lAmostra :=	iif( EE7->EE7_AMOSTR = "4"	,.t.	,.f.)
		
		//Verificar dados logisticos
		if !lAmostra
			PBK->( DbSetOrder(1) ) 
			If PBK->( DbSeek( avKey( xFilial("PBK"),	"PBK_FILIAL") + avKey( SC5->C5_PEDEXP	,"PBK_PEDEXP" ) ) )
				if Empty( PBK->PBK_CODDST )
					cMsg	+= iif( Empty(cMsg),"Destinatário"	," / Destinatário")	
					lPBKOK	:= .f.	
					lRet	:= .f.		
				endif	
						
				if lMarit .and. Empty( PBK->PBK_CDNAV )
					cMsg	+= iif( Empty(cMsg),"Navio"			," / Navio")
					lPBKOK	:= .f.
					lRet	:= .f.
				Endif
				
				if !lPBKOK
					cMsgPro := "Existem dados obrigatórios para emissão da nota fiscal não preenchidos" + Chr(13) + cMsg
					cMsgSol := "Inclua os dados obrigatórios em dados logísticos"
					
					Help( Nil, Nil, 'F0401910', Nil, cMsgPro, 1, 0, Nil, Nil, Nil, Nil, Nil, {cMsgSol})
				Endif
			Else
				cMsg	+= iif( Empty(cMsg),"Destinatário"	," / Destinatário")		
				If lMarit
					cMsg	+= iif( Empty(cMsg),"Navio"			," / Navio")	
				Endif	
				cMsgPro := "Existem dados obrigatórios para emissão da nota fiscal não preenchidos" + Chr(13) + cMsg
				cMsgSol := "Inclua os dados obrigatórios em dados logísticos"
				
				Help( Nil, Nil, 'F0401910', Nil, cMsgPro, 1, 0, Nil, Nil, Nil, Nil, Nil, {cMsgSol})
				lPBKOK	:= .f.
				lRet	:= .f.
			Endif
		Endif
	Endif
	
	if lPBKOK .and. lMarit

		/*/ACSJ 09/03/2020 Ticket Id 689
		aAdd( aPergs ,{1, AVSX3("EX9_CONTNR"	,5)	,cContnr	,AVSX3("EX9_CONTNR"	,6)	,"U_F0401913()"	,,'.T.',80,.T.})
		---------------------------------------------------------------------------------------------------------------/*/	
		//Alterado a mascara do campo PCJ_CONTNR - Ronaldo Dantas - MIT044 - P04093 - SMI050 - Alteração GAP 099 E GAP 145 - 09/11/2020 
		aAdd( aPergs ,{1, AVSX3("PCJ_CONTNR"	,5)	,cContnr	,"@E! AAAA 999 999-9"	,				,,'lContr'		,80	,lContr})
		aAdd( aPergs ,{1, AVSX3("PCJ_TARA"		,5) ,nTara  	,AVSX3("PCJ_TARA"	,6) ,				,,'lTara'		,80	,lTara})
		aAdd( aPergs ,{1, AVSX3("PCJ_LACRE"		,5) ,cLacre 	,AVSX3("PCJ_LACRE"	,6) ,				,,'lLacre'		,80	,lLacre})
		aAdd( aPergs ,{1, AVSX3("PCJ_LCSIF"		,5)	,cXlcSIF	,AVSX3("PCJ_LCSIF"	,6)	,				,,'lLcSif'		,80	,lLcSif})
		aAdd( aPergs ,{1, AVSX3("PCJ_LCGOV"		,5)	,cXlcGOV	,AVSX3("PCJ_LCGOV"	,6)	,				,,'lTemLcGv'	,80	,lTemLcGv})
		aAdd( aPergs ,{1, AVSX3("PCJ_M3"		,5) ,nXm3   	,AVSX3("PCJ_M3"		,6) ,				,,'lM3'			,80	,lM3})
	
		If ParamBox(aPergs ,"Cadastro de Container - Pedido:"+Alltrim(SC5->C5_NUM),aRet,nil,nil,nil,nil,nil,nil,nil,.f.,.f.)  
			RecLock("PC8", !lTemX5 )
				  
				PC8->PC8_FILIAL	:= xFilial("PC8")
				PC8->PC8_CONTNR	:= Alltrim(Mv_Par01) 
				PC8->PC8_TARA  	:= Mv_Par02
				PC8->PC8_LACRE 	:= Alltrim(Mv_Par03)			
				PC8->PC8_XLCSIF	:= Alltrim(Mv_Par04)
				PC8->PC8_XLCGOV	:= Alltrim(Mv_Par05)
				PC8->PC8_XM3   	:= Mv_Par06
				PC8->PC8_XPEDID	:= Alltrim(SC5->C5_PEDEXP)
				PC8->PC8_NUM   	:= SC5->C5_NUM
			
			PC8->(MSUNLOCK())
			
			lRet := .T.
		Else      
			lRet := .F.
		EndIf
		Pergunte("MT460A", .F.)
	Endif
		
Return(lRet)

//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0401911
//TODO Validacao do pedido para geracao do DOC de Saida
@author wanderley.silva
@since 10/07/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
//-----------------------------------------------------------------------------
User Function F0401911()
    Local aAreaSC9 := GetArea("SC9")
    Local aAreaEE7 := GetArea("EE7")
    Local lRet     := .t.
    
    //Posicionar no EEC para ver se o processo é ou não Break Bulk
    
      
    If !Empty(SC5->C5_PEDEXP) //Verifica se a NF sera referente 
	    EE7->(DbSetOrder(1))
	    If EE7->(dbSeek(xFilial("EE7")+AvKey(SC5->C5_PEDEXP,"EE7_PEDIDO")))
	    	If EE7->EE7_XBRKBK = "2"	//Abre a janela somente se 2-Nao BreakBulk [ACSJ-ID89] 
	    		lRet := U_F0401910()
	    	EndIf
	    EndIf
    EndIf
    
    
    RestArea(aAreaEE7)
    RestArea(aAreaSC9)
Return (lRet)


//-----------------------------------------------------------------------------
/*/{Protheus.doc} F040192
//TODO Grava numero do Container na Tabela PCJ / SF2
@author wanderley.silva
@since 10/07/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
//-----------------------------------------------------------------------------
User Function F0401912(nReg)
    Local cPedido	:= SC5->C5_NUM  
    Local cContnr	:= ""
  
    Dbselectarea("PC8")
	PC8->(dbSetOrder(1)) //PC8_FILIAL+PC8_NUM                                                                                                                                              
	IF PC8->(dbSeek(xFilial("PC8")+cPedido))
		
		If !EMPTY(PC8->(PC8_CONTNR+PC8_LACRE+PC8_XLCSIF+PC8_XLCGOV)) 

			//ACSJ 09/03/2020 - Ticket Id 689
			Reclock('PCJ', .t.)	
				PCJ->PCJ_FILIAL := xFilial('PCJ')
				PCJ->PCJ_PEDIDO := SC5->C5_PEDEXP
				PCJ->PCJ_CONTNR := PC8->PC8_CONTNR				
				PCJ->PCJ_TARA   := PC8->PC8_TARA
				PCJ->PCJ_LACRE  := PC8->PC8_LACRE
				PCJ->PCJ_LCSIF 	:= PC8->PC8_XLCSIF
				PCJ->PCJ_LCGOV 	:= PC8->PC8_XLCGOV				
				PCJ->PCJ_M3    	:= PC8->PC8_XM3
			PCJ->(MSUNLOCK())	

			cContnr	:= PC8->PC8_CONTNR
			
			RecLock("PC8", .F.)
			PC8->(dbDelete())
			PC8->(MSUNLOCK())
		
		EndIf

	EndIf

    If !Empty(cContnr)    	
		SF2->F2_XCNTNR := cContnr
    EndIf
    
Return Nil
 	

//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0401914
//TODO Roda no PE M460MARK para validacao do pedido para geracao do DOC de Saida
@author wanderley.silva
@since 23/08/2019
@version 1.0
@return lRet 
@param cMarca, characters, parametro do PE M460MARK
@param lInverte, logical, parametro do PE M460MARK
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0401914(cMarca, lInverte)
    Local aArea     	:= GetArea()
    Local aAreaC9   	:= SC9->(GetArea())
    Local aAreaC5   	:= SC5->(GetArea())
    Local lRet      	:= .T.    
	Local cQuery1   	:= ""
	Local cAliasQry    	:= GetNextAlias()
	Local cAprov    	:= ""
	Local cPedAtu   	:= ''	
	Local nLstRecP  	:= 0
	Local lXBRKBK  	 	:= ''
	Local nX

	Local lFatByDAK 	:= (FunName() == "MATA460B")
	Local lIntWMS  		:= IntWms()
	Local lFilDAK   	:= OsVlEntCom() <> 1
	Local lExport		:= .f.

	Local aSavMVPar		:= {}
	Local nCntMv		:= 0
	Local cMVPAR		:= ""
	Local cFLoren   	:= Alltrim(GetMV("FS_C040701", .T., "")) // filiais Lorenz
	Local nValFre		:= 0
	Local nAICFre 		:= 0
	Local nIcmFre 		:= 0
	Local lSC5Grv		:= .T.	
	Local cUFOrig		:= ""
	Local cUFDest		:= ""

	//Variaveis para tratativa da SM038
	Local cCFOPRem   	:= Alltrim(GetMV("FS_C040721", .T., "")) // CFOP Remessa	
	Local cTipoRem		:= ""
	Local aParceria		:= {}
	Local aPedAuton		:= {}

	Private cMotivo 	:= ""
	Private aData   	:= {}
    
	// salva o conteúdo dos MV_PARnn
	For nCntMv := 1 TO 60
		cMVPAR := "MV_PAR" + StrZero(nCntMv,2)
		aadd( aSavMVPar, &cMVPAR)
	Next

    //Criando a consulta
    cQuery1 += " SELECT DISTINCT SC5.R_E_C_N_O_ AS C5_RECNO, SC9.R_E_C_N_O_ AS C9_RECNO, C9_PEDIDO	,C5_PEDEXP "                                         
    cQuery1 += " FROM "+RetSQLName("SC9")+" SC9 "                             
    cQuery1 += " INNER JOIN "+RetSQLName("SC5")+" SC5 "                 
    cQuery1 += "      ON SC5.D_E_L_E_T_='' "                                     
    cQuery1 += "      AND C5_FILIAL = C9_FILIAL "                             
    cQuery1 += "      AND C5_NUM = C9_PEDIDO "

	If lFatByDAK
		cQuery1 += "  INNER JOIN " + RetSQLName("DAI") + " DAI ON( DAI.D_E_L_E_T_ = ''	AND C5_FILIAL = DAI_FILIAL	AND C5_NUM = DAI_PEDIDO ) "
		cQuery1 += "  INNER JOIN " + RetSQLName("DAK") + " DAK ON( DAK.D_E_L_E_T_ = ''	AND DAI_FILIAL = DAK_FILIAL AND DAI_COD = DAK_COD 		AND DAI_SEQCAR = DAK_SEQCAR ) "
	Endif
		
    cQuery1 += " WHERE SC9.D_E_L_E_T_ = ' ' "                                  
    cQuery1 += "  AND C9_FILIAL='"+xFilial("SC9")+"' "                     
    cQuery1 += "  AND C9_OK"+Iif(lInverte, "<>", "=")+ "'"+cMarca+"' "   

	if	lFatByDAK

		//Restaurando a pergunta do MATA461 para gerer Query da SC9
    	Pergunte("MT461B",.F.) //restauro as variaveis de memoria

		cQrySC9	:= ""
		cQryDAK := " AND DAK_FILIAL = '"+xFilial("DAK")+"'"

		If (MV_PAR01 == 1)
			cQryDAK += " AND DAK_FEZNF <> '1'"
		EndIf

		If !(Empty(MV_PAR03) .And. Upper(MV_PAR04) == Replicate('Z', Len(MV_PAR04)))
			cQryDAK += " AND DAK_COD >= '"+MV_PAR03+"'"
			cQryDAK += " AND DAK_COD <= '"+MV_PAR04+"'"
			cQrySC9 += " AND SC9.C9_CARGA >= '"+MV_PAR03+"'"
			cQrySC9 += " AND SC9.C9_CARGA <= '"+MV_PAR04+"'"
		EndIf

		If !(Empty(MV_PAR05) .And. Upper(MV_PAR06) == Replicate('Z', Len(MV_PAR06)))
			cQryDAK += " AND DAK_CAMINH >= '"+MV_PAR05+"'"
			cQryDAK += " AND DAK_CAMINH <= '"+MV_PAR06+"'"
		EndIf

		cQrySC9 += " AND SC9.C9_DATALIB >= '"+Dtos(MV_PAR07)+"'"
		cQrySC9 += " AND SC9.C9_DATALIB <= '"+Dtos(MV_PAR08)+"'"

		// Seleciona somente cargas que tiveram o servico executado pelo WMS
		If lIntWMS .And. MV_PAR09 == 2
			// Nao deve filtrar pedido, pois só devem aparecer as cargas totalmente liberadas
			cQrySC9 += " AND NOT EXISTS (SELECT 1"
			cQrySC9 +=                   " FROM "+RetSqlName("SC9")+" SC9B"
			cQrySC9 +=                  " WHERE SC9B.C9_FILIAL  = SC9.C9_FILIAL"
			cQrySC9 +=                    " AND SC9B.C9_CARGA   = SC9.C9_CARGA"
			cQrySC9 +=                    " AND SC9B.C9_SEQCAR  = SC9.C9_SEQCAR"
			cQrySC9 +=                    " AND SC9B.C9_BLWMS   = '01'"
			cQrySC9 +=                    " AND SC9B.D_E_L_E_T_ = ' ')"
		EndIf

		cQryDAK += " AND DAK_DATA >= '"+DToS(MV_PAR10)+"'"
		cQryDAK += " AND DAK_DATA <= '"+Dtos(MV_PAR11)+"'"

		If lIntWMS .And. SuperGetMV("MV_WMSNEW",.F.,.F.) .And.;
			!(Empty(MV_PAR12) .And. Upper(MV_PAR13) == Replicate('Z', Len(MV_PAR13)))
			cQrySC9 += " AND SC9.C9_ROMEMB >= '"+MV_PAR12+"'"
			cQrySC9 += " AND SC9.C9_ROMEMB <= '"+MV_PAR13+"'"
		EndIf

		cQryDAK += " AND EXISTS (SELECT 1"
		cQryDAK +=               " FROM "+RetSqlName("DAI")+" DAI"
		cQryDAK +=              " INNER JOIN "+RetSqlName("SC9")+" SC9"
		cQryDAK +=                 " ON SC9.C9_FILIAL  = "+Iif(lFilDAK,OsFilQry("SC9","DAI.DAI_FILPV"),"'"+xFilial("SC9")+"'")
		cQryDAK +=                " AND SC9.C9_CARGA   = DAI.DAI_COD"
		cQryDAK +=                " AND SC9.C9_SEQCAR  = DAI.DAI_SEQCAR"
		cQryDAK +=                " AND SC9.C9_PEDIDO  = DAI.DAI_PEDIDO"
		cQryDAK +=                " AND SC9.D_E_L_E_T_ = ' '"
		cQryDAK +=              " WHERE DAI.DAI_FILIAL = '"+xFilial("DAI")+"'"
		cQryDAK +=                " AND DAI.DAI_COD    = DAK_COD"
		cQryDAK +=                " AND DAI.DAI_SEQCAR = DAK_SEQCAR"
		cQryDAK +=                " AND DAI.D_E_L_E_T_ = ' ' "
		cQryDAK +=                cQrySC9 + ")"

		cQuery1	+= cQryDAK
		
	Else
		//Restaurando a pergunta do MATA461 para gerar Query da SC9
   		Pergunte("MT461A",.F.) //restauro as variaveis de memoria

		If ( MV_PAR01 == 1 )
			cQuery1 += " AND C9_BLEST <> '10'"
			cQuery1 += " AND C9_BLEST <> 'ZZ'"    
		EndIf
		If ( MV_PAR03 == 1 )
			cQuery1 += "  AND C9_CLIENTE BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR08 + "' "
			cQuery1 += "  AND C9_LOJA    BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR10 + "' "        
			cQuery1 += "  AND C9_PEDIDO  BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' "
			cQuery1 += "  AND C9_DATALIB BETWEEN '"+Dtos(MV_PAR11)+"' AND '"+Dtos(MV_PAR12)+"' "	    
			If ( !Empty( MV_PAR14 ) ) .And. ( ValType(MV_PAR14) == 'D' )
				cQuery1 += "  AND C9_DATENT >= '" + DToS(MV_PAR14) + "' "
			EndIf
			If ( !Empty( MV_PAR15 ) ) .And. ( ValType(MV_PAR15) == 'D' )
				cQuery1 += "  AND C9_DATENT <= '" + DToS(MV_PAR15) + "' "
			EndIf
		
		EndIF
	Endif

    cQuery1 += " ORDER BY C9_PEDIDO " 
    
    cQuery1 := ChangeQuery(cQuery1)
     
    //Executando a Clausula
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery1),cAliasQry ,.F.,.T.)
	
    //Indo ao top e verificando se há registros
    (cAliasQry)->(DbGoTop())
    
    /*/ P04019 - GAP145: So faturar itens de um pedido por nota /*/
	cPedAtu   := (cAliasQry)->C9_PEDIDO
	lExpAtu	  := !Empty( (cAliasQry)->C5_PEDEXP )

	While !(cAliasQry)->(Eof())   

		lExport	:= .f.
		If !Empty( (cAliasQry)->C5_PEDEXP ) // ACSJ - 07/02/2020 SM 076 Não é permitido dois pedidos de exportação na mesma nota fiscal 
			lExport	:= .t.
		EndIf

		If (cAliasQry)->C9_PEDIDO <> cPedAtu .and. lExport <> lExpAtu

			if	lFatByDAK // ACSJ 12/02/2020 SM 076 - Faturamento por carga MATA460B  

				cMsgPro	:= "Existem pedidos de mercado interno e mercado externo na mesma carga"
				cMsgSol := "altere a carga para haver apenas um tipo de mercado (Interno ou externo)"

				Help(,, "Geracao de Container", "Geracao de Container", cMsgPro, 1, 1,,,,,,;
					{cMsgSol})  

			Else
				
				cMsgPro	:= "Pedidos de Venda diferentes para a mesma nota fiscal.."
				cMsgSol := "Fature apenas itens do mesmo pedido para geração de uma nota fiscal."
				Help(,, "Geracao de Container", "Geracao de Container", cMsgPro, 1, 1,,,,,,;
					{cMsgSol})  
			EndIf

			// restaura o conteúdo dos MV_PARnn
			For nCntMv := 1 TO Len(aSavMVPar)
				cMVPAR := "MV_PAR" + StrZero(nCntMv,2)
				&cMVPAR := aSavMVPar[nCntMv]
			Next

			RestArea(aAreaC5)
			RestArea(aAreaC9)
			RestArea(aArea)
			Return .F.
		EndIf
		(cAliasQry)->(DbSkip())
	EndDo    

    //Indo ao top e verificando se há registros
    (cAliasQry)->(DbGoTop())
        
    // Só vai validar registros oriundos de pedido de exportacao e Break Bulk = 2-Nao
   	While !(cAliasQry)->(Eof())

		SC5->(DbGoTo((cAliasQry)->C5_RECNO)) // Posiciono no Registro da SC5
		IF !Empty( (cAliasQry)->C5_PEDEXP )
			EE7->(DbSetOrder(1))
			If EE7->( dbSeek( SC5->C5_FILIAL + AvKey(SC5->C5_PEDEXP,"EE7_PEDIDO") ) )
				cPedAtu   := (cAliasQry)->C9_PEDIDO
				lXBRKBK   := (EE7->EE7_XBRKBK = '1')

				//----------------------------------------------------------
				//Chama Funcao para Validar CFOP X ATO CONCESSÓRIO -  SMI024
				//----------------------------------------------------------
				lRet:= VldAto(EE7->EE7_PEDIDO)
				if !lRet
					cMsgPro := "O CFPO utilizado no pedido de venda " + EE7->EE7_PEDFAT + " / pedido exportação " + EE7->EE7_PEDiDO + " exige vinculação de Ato Concessório. Ato Concessório não vinculado" 
					cMsgSol := "Informe Ato Concessórios para todos os itens do pedido" 
					Help( Nil, Nil, 'F0401916', Nil, cMsgPro, 1, 0, Nil, Nil, Nil, Nil, Nil, {cMsgSol})
					Exit
				Endif
				//-----------------------------------------------------
				
				While !(cAliasQry)->(Eof()) .and. (cAliasQry)->C9_PEDIDO == cPedAtu
					SC9->(DbGoTo((cAliasQry)->C9_RECNO)) // Posiciono no Registro da SC9

					//-----------------------------------------------------
					//Chama Funcao para Validar Regra do Desacordo. GAP 112
					//-----------------------------------------------------
					lRet := u_F0402506(SC9->C9_PEDIDO, SC9->C9_XDTPRLT)
			
					If !lRet 
						If Empty(cAprov)
							cAprov := u_F0402504()
						EndIf
						If Empty(cAprov)
							Help(,, "Regra do Desacordo", "Regra do Desacordo", "Aprovador não selecionado, o processo será cancelado.", 1, 1,,,,,,;
								{"Selecione o Aprovador."})  

							u_F0402507(cAprov, "Cancelado: " + cMotivo)

							// restaura o conteúdo dos MV_PARnn
							For nCntMv := 1 TO Len(aSavMVPar)
								cMVPAR := "MV_PAR" + StrZero(nCntMv,2)
								&cMVPAR := aSavMVPar[nCntMv]
							Next

							RestArea(aAreaC5)
							RestArea(aAreaC9)
							RestArea(aArea)
							Return(.F.)
						Else						
							//Grava Log de Inconsistencia x Usuario x Aprovador
							u_F0402507(cAprov, "Aprovado: " + cMotivo)
							lRet := .T.
						EndIf
					EndIf
					nLstRecP := (cAliasQry)->(Recno()) // Salvo a posicao do pedido que esta sendo processado
					
					(cAliasQry)->(DbSkip())
				EndDo
			
				//---------------------------------------------------------------------------------------------------------------
				//Caso tenha encontrado todas as informacoes para Validacao da Regra do Desacordo e Caso tenha Itens em Desacordo 
				//---------------------------------------------------------------------------------------------------------------
				If !Empty(aData) 
					If Empty(cAprov)
						//Chama Tela de Desacordo Alertando ao Usuario.
						cAprov := u_F0402503(aData)
					EndIf
			
					If !Empty(cAprov)
						lRet := .T.
					Else			
						Help(,, "Regra do Desacordo", "Regra do Desacordo", "Aprovador não selecionado, o processo será cancelado.", 1, 1,,,,,,;
							{"Selecione o Aprovador."})  
						lRet := .F.	
					EndIf 
			
					For nX := 1 To Len(aData)	
						SC9->(DbSetOrder(1))
						If SC9->(DbSeek(xFilial("SC9") + aData[nX][6] + aData[nX][7] ))
							u_F0402507(cAprov, iif(lRet, "Aprovado: Datas em Desacordo", " Cancelado: Datas em Desacordo"))
						EndIf
					Next nX
				
				Else
					lRet := .T. 
				EndIf  
				
				(cAliasQry)->(DbGoTo(nLstRecP)) // Posiciono no ultimo item do Pedido cPedAtu.
				
				//----------------------------	
				// GAP 145 - Tela de Container
				//----------------------------
				IF lRet  
					IF !U_F0401911() //ACSJ 28/05/2020-ID777 - Valida se é breakbulk e executa se não F040910()
						lRet := .F.
						EXIT
					EndIf
				EndIf
			Endif
		Else
			// MIT044 – P04070 - SM086 - Cálculo de frete relacionado a despesas acessórias
			If !lFatByDAK	
				If !SC5->C5_FILIAL $ cFLoren
					If aScan( aPedAuton, SC5->C5_FILIAL + SC5->C5_NUM) == 0 // para passar somente 1 vez por pedido
						aadd( aPedAuton, SC5->C5_FILIAL + SC5->C5_NUM)

						nValFre := 0
						nAICFre := 0
						nIcmFre := 0
						lSC5Grv	:= .T.
						cUFOrig	:= ""
						cUFDest	:= ""

						If U_F0407011(lSC5Grv, @cUFOrig, @cUFDest) // //Valida se o pedido está na regra para o frete autonomo
							nValFre := U_F0407021(.T.,lFatByDAK) // Calculo de frete autonomo. //- Ricardo
							If nValFre <= 0
								Help( Nil, Nil, 'F0407020', Nil, "Faturamento do pedido " + SC5->C5_NUM + " bloqueado devido ao retorno do cálculo de frete autônomo estar sem valor", 1, 0, Nil, Nil, Nil, Nil, Nil, {""})
								Alert("Processo cancelado!")
								lRet := .F.
								Break
							Else
								nAICFre := U_F0407012(cUFOrig, cUFDest) // icms frete
								nIcmFre := Round(((nValFre * nAICFre) / 100),2)
							EndIf
						EndIf

						SC5->(RecLock("SC5",.F.))
							SC5->C5_XVALFRE := nValFre
							SC5->C5_XAICFRE := nAICFre
							SC5->C5_XICMFRE := nIcmFre
						SC5->(MsUnlock())

						If !lRet
							EXIT
						Endif
					Endif
				EndIf
			Endif	
		EndIf
		
		//MIT044 – P04072 - SMI038 - Processo de Venda Conta e Ordem
		SC9->(DbGoTo((cAliasQry)->C9_RECNO))
		If !Empty(Posicione("SC6",1,SC9->C9_FILIAL + SC9->C9_PEDIDO + SC9->C9_ITEM + SC9->C9_PRODUTO,"C6_CONTRAT"))
			If Alltrim(SC6->C6_CF) $ cCFOPRem
				cTipoRem := 'R'
			Else
				cTipoRem := 'V'
			EndIf
			AaDd(aParceria,{SC6->C6_CONTRAT, cTipoRem, SC6->C6_NUM, SC6->C6_PRODUTO, SC9->C9_QTDLIB})	 
		EndIf

		(cAliasQry)->(DbSkip())		
   	EndDo

	//Validação das mensagens para conta e ordem
	//MIT044 – P04072 - SMI038 - Processo de Venda Conta e Ordem
	If lRet .And. Len(aParceria) > 0
		lRet := U_F0407210(aParceria)
	EndIf
	
	(cAliasQry)->(DbCloseArea())

	// restaura o conteúdo dos MV_PARnn
	For nCntMv := 1 TO Len(aSavMVPar)
		cMVPAR := "MV_PAR" + StrZero(nCntMv,2)
		&cMVPAR := aSavMVPar[nCntMv]
	Next

    RestArea(aAreaC5)
    RestArea(aAreaC9)
    RestArea(aArea)
    
Return lRet

//-----------------------------------------------------------------------------
/*/{Protheus.doc} F0401915
//TODO Rotina para exclusao de conteiners do PE M521DNFS
@author wanderley.silva
@since 23/08/2019
@version 1.0
@return lRet 
@param cMarca, characters, parametro do PE M460MARK
@param lInverte, logical, parametro do PE M460MARK
@type function
/*/
//-----------------------------------------------------------------------------
User Function F0401915(cContNr)
Local nInc   := 0
Local cQuery := 0
Local cMsgErr:= ''
Local aQuery := {}

cQuery := " SELECT R_E_C_N_O_ PCJ_RECNO "
cQuery += " FROM "+RetSqlName("PCJ")+" PCJ "
cQuery += " WHERE D_E_L_E_T_ = ' ' "
cQuery += " AND PCJ_FILIAL = '"+xFilial("PCJ")+"' "
cQuery += " AND PCJ_CONTNR = '"+cContNr+"' "

aQuery := JurSQL(cQuery, {"PCJ_CONTNR","PCJ_RECNO"})

For nInc:= 1 to len(aQuery)
	PCJ->(DbGoTo(aQuery[nInc,2]))
	IF RecLock("PCJ",.F.)
		DbDelete()
		MsUnlock()
	Else
		cMsgErr+= aQuery[nInc,1]+", "
	EndIf	
Next

If !Empty(cMsgErr)
	cMsgErr:= Left(cMsgErr,len(cMsgErr)-1)
	Help(,, "F0401915", "F0401915", "Não foi possível excluir automaticamente o(s) Conteiner(s):"+cMsgErr, 1, 1,,,,,,;
		{"Solicite exclusão manual no cadastro de Conteiners."})  
EndIf
Return(NIL)


//-----------------------------------------------------------------------------
/*/{Protheus.doc} ValAto
//Valida CFOP x Ato concessório
@author Alexandre Caetano
@since 05/06/2020
@version 1.0
@return lRet 
@param cPedExp - Pedido de Exportação
@type function
/*/
//-----------------------------------------------------------------------------
Static Function VldAto(cPedExp)
	Local lOkAto	:= .t.
	Local cQry		:= ""
	Local cNmArq01	:= GetNextAlias()
	Local cCFOPdb	:= SuperGetmv("FS_C040171", .F., "")
								
	cQry	:= " SELECT EE8_PEDIDO	,EE8_ATOCON	,EE8_SEQED3	,EE8_CF "
	cQry	+= " FROM " + RetSQLName("EE8") + " EE8 "
	cQry	+= " WHERE EE8_FILIAL = '" + xFilial("EE8") + " ' "
	cQry	+= "   AND EE8_PEDIDO = '" + cPedExp        + " ' "
    cQry	+= "   AND EE8.D_E_L_E_T_ = '' "
	
	cQry    := ChangeQuery(cQry)

    If Select(cNmArq01) > 0
        ( cNmArq01 )->( dbCloseArea() )
    EndIf

    dbUseArea( .t., "TopConn", TCGenQry(,,cQry),cNmArq01, .F., .F. )
    ( cNmArq01 )->( dbGoTop() )
	Do While ( cNmArq01 )->(!Eof() )

		if Alltrim( ( cNmArq01 )->EE8_CF ) $ cCFOPdb  .and. ;
		   ( Empty( ( cNmArq01 )->EE8_ATOCON ) .or. Empty( ( cNmArq01 )->EE8_SEQED3 ) )

			lOkAto	:= .f.
			Exit
 
		Endif

		 ( cNmArq01 )->( dbSkip() )
	EndDo

	( cNmArq01 )->( dbCloseArea() )
	
Return(lOkAto)
