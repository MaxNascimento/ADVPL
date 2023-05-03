#INCLUDE 'protheus.ch'
#INCLUDE 'parmtype.ch'
#Include "TOPCONN.CH"
#Define ENTER (Chr(13)+Chr(10))
/*/{Protheus.doc} G0108642
//TODO usado no ponto de entrada GFEA0508 após calculo do romaneio de carga 
com sucesso (GWN_CALC = 1), se o parametro ES_43CTFRA estiver ligado gravar 
o contrato de frete por romaneio automatico (Z20).
@author lucio.ferro
@since 29/08/2019
@version 1.000

@author Ricardo Mendes(TOTVS)
@since 18/11/2019
@version 2.000

@author lucio.ferro
@since 05/12/2019
@version 3.000
@return ${return}, ${return_description}

@type function
/*/
user function G0108642(cNrRom)
	Local lRet := .T.
	Local lEs43ctfr		:= SuperGetMV("ES_43CTFRA",.F.,.F.)
	Local aArea			:= GetArea()
	Local aAreaGWN		:= GWN->(GetArea())

	Private lMstMsg		:= !IsBlind()

	//GWN->GWN_CALC == "1" --> indica que o romaneio foi calculado com sucesso
	If lEs43ctfr .and. GWN->GWN_CALC == "1"
	/*
	-- Conforme reunião com Vitor Costa e Victor Saldivar e Rubens em 02/05/2023
	-- Ficou combinado de comentar esse bloco de código pois a mensagem está
	-- Atrasando o faturamento e não estamos utilizando o contrato de frete
		IF (Empty(GWN->GWN_PLACAD) .OR. Empty(GWN->GWN_CDMTR))
			IF lMstMsg
				U_fMsgHelp(,"Contrato de Frete Automático habilitado, porém os campos relacionados a Placa ou Motorista, não preenchidos.", "Verifique os campos Placa("+GWN->GWN_PLACAD+") ou Motorista("+GWN->GWN_CDMTR+").")
			Else
				U_fCriaMSG("Help [G0108642] -> Contrato de Frete Automático habilitado, porém os campos relacionados a Placa ou Motorista, não preenchidos.")
			EndIF
			Return .F.
		EndIF
	*/
		IF lMstMsg
			lRet := Processa( {|| GrCTRFrt(cNrRom) }, "Aguarde...", "Inserindo vinculo com contrato de frete por romaneio",.T.)
		Else
			GrCTRFrt(cNrRom)
		EndiF
	EndIF

	GWN->(RestArea(aAreaGWN))
	RestArea(aArea)	

return lRet

//Função para gerar a estrutura de Contrato de Frete
Static Function GrCTRFrt(cNrRom) 	
	Local lRet			:= .T.
	Local lAchouGU3		:= .F.
	Local cEmitGU3		:= ""

	Private cCentro		:= SuperGetMV("ES_43CTTFR",.F.,'220116')
	Private cItemCent	:= GetMV("ES_43CCTRA")

	Private lGeraGRIS	:= .F.
	Private nPercGris	:= 0

	Private lGeraADIA	:= .F.
	Private nPercADIA	:= 0

	Private cCdTransp	:= ""
	Private cCdCliTra	:= ""
	Private cLjCliTra	:= "" 
	Private cCdForTrp	:= ""
	Private cLjForTrp	:= ""

	Private cNmCliTra	:= ""
	Private cNumCtrFR	:= ""
	Private cNumABAS	:= ""
	Private nVlrMerca	:= 0
	Private nVlrFrete	:= 0
	Private nQtRoman	:= 0
	Private cTipFret	:= ""
	Private cTipVei		:= Posicione("DA3", 3, xFilial("DA3") + GWN->GWN_PLACAD, "DA3_TIPVEI")

	nVlrMerca	:= U_G0108635(GWN->GWN_FILIAL, GWN->GWN_NRROM)
	nVlrFrete	:= U_fVlrFrt(GWN->GWN_NRROM)
	// buscar o peso liquido ou bruto ou quantidade dependendo do parametro(novo)
	nQtRoman	:= U_fQtdRom(GWN->GWN_FILIAL, GWN->GWN_NRROM)

	//validar se existe contrato de frete amarrado ao romaneio de carga apenas atualizar valor contrato
	If ValRomCtr(GWN->GWN_FILIAL,GWN->GWN_NRROM, nVlrFrete, nQtRoman, .F.)
		return .T.
	Else
		cEmitGU3 := Posicione("GU3",1,xFilial("GU3")+GWN->GWN_CDTRP,"GU3_IDFED")
		//Buscar as informações relacionadas a GRIS, Adiantamento, Cliente, Loja e Transportadora
		lAchouGU3 := U_fPsqInfo(cEmitGU3, GWN->GWN_NRROM, GWN->GWN_PLACAD)

		IF lAchouGU3
			IncluiZ20(GWN->GWN_FILIAL,GWN->GWN_NRROM,GWN->GWN_PLACAD,GWN->GWN_CDMTR)
		EndIF
	EndIf

return lRet

//Função para calcular qual é o saldo do contrato de frete
User Function CalcSld(cCtrFrt, lGrvSld)
	Local aRetoAdt	:= {}
	Local nAdtPaga	:= 0
	Local nAdtRece	:= 0
	Local nVlrCtr	:= 0
	Local nSldFrt	:= 0

	Default lGrvSld := .F.

	IF !Empty(cCtrFrt)
		DbSelectArea("Z20")
		Z20->(DbSetOrder(1))
		If Z20->(DbSeek(xFilial("Z20")+  Padr(cCtrFrt, TamSX3("Z20_CTRFRT")[1]) ))

			IF ((Z20->Z20_STATUS != "F" .AND. Z20->Z20_STATUS != "C") .OR. (Z20->Z20_STATUS == "F" .AND. Z20->Z20_SLDCTR > 0))
				aRetoAdt	:= AchAdtFr(cCtrFrt, Z20->Z20_PLACA)
				nAdtPaga	:= IIF(Len(aRetoAdt) > 0, aRetoAdt[1], 0)
				nAdtRece	:= IIF(Len(aRetoAdt) > 0, aRetoAdt[2], 0)
	
				nVlrCtr := Z20->Z20_VLRCTR //Valor do Contrato
				nSldFrt := ((nVlrCtr + nAdtRece) - nAdtPaga)//Saldo Contr.
				
				nSldFrt := IIF(nSldFrt <= 0, 0, nSldFrt)
	
				IF lGrvSld
					RecLock('Z20',.F.)
					Z20->Z20_SLDCTR := nSldFrt
					Z20->Z20_STATUS := IIF(nSldFrt <= 0, "T" , "P")
					Z20->Z20_USRALT := __CUSERID
					Z20->Z20_DATALT := Date()
					Z20->Z20_HORALT := Substr(Time(),1,5)	
					Z20->(MsUnlock())	
				EndIF
			Else
				nSldFrt := Z20->Z20_SLDCTR
			EndIF
		EndIF
	EndIF

Return IIF(lGrvSld, .T., nSldFrt)

//Função para verificar se o contrato de frete já existe, apenas atualiza os valores
Static Function ValRomCtr(cFilRom,cNrRoman, nVlrAtu, nQtdAtu, lDireto)
	Local cCtrFrt	:= Posicione("Z20",5,xFilial("Z20")+cNrRoman,"Z20_CTRFRT")
	Local lRet 		:= .T.
	Local aRetoAdt	:= {}
	Local nAdtPaga	:= 0
	Local nAdtRece	:= 0

	Default lDireto := .F.

	If !Empty(cCtrFrt)
		lRet := .T.

		DbSelectArea("Z20")
		Z20->(DbSetOrder(1))
		If Z20->(DbSeek(xFilial("Z20")+  Padr(cCtrFrt, TamSX3("Z20_CTRFRT")[1]) ))

			aRetoAdt	:= AchAdtFr(cCtrFrt, Z20->Z20_PLACA)
			nAdtPaga	:= IIF(Len(aRetoAdt) > 0, aRetoAdt[1], 0)
			nAdtRece	:= IIF(Len(aRetoAdt) > 0, aRetoAdt[2], 0)

			IF lDireto
				RecLock('Z20',.F.)
				Z20->Z20_PESOBR	:= nQtdAtu
				Z20->Z20_PESOLI := nQtdAtu
				Z20->Z20_VLRFRE	:= nVlrAtu	
				Z20->Z20_VLRCTR := Z20->Z20_VLRFRE+Z20->Z20_VLRPED+Z20->Z20_VLRPER+Z20->Z20_VLRDES+Z20->Z20_VLRDPC+Z20->Z20_VLROUT//Vlr.Contrato
				Z20->Z20_SLDCTR := ((Z20->Z20_VLRCTR +nAdtRece) - nAdtPaga)//Saldo Contr.
				Z20->(MsUnlock())	
			Else
				IF lMstMsg
				/* 
				-- Conforme reunião com Vitor Costa e Victor Saldivar e Rubens em 02/05/2023
				-- Ficou combinado de comentar esse bloco de código pois a mensagem está
				-- Atrasando o faturamento e não estamos utilizando o contrato de frete
					If MSGYESNO("Contrato de frete já existente, tem certeza que deseja atualizar os valores?","Atenção")
						RecLock('Z20',.F.)
						Z20->Z20_PESOBR	:= nQtdAtu
						Z20->Z20_PESOLI := nQtdAtu
						Z20->Z20_VLRFRE	:= nVlrAtu	
						Z20->Z20_VLRCTR := Z20->Z20_VLRFRE+Z20->Z20_VLRPED+Z20->Z20_VLRPER+Z20->Z20_VLRDES+Z20->Z20_VLRDPC+Z20->Z20_VLROUT//Vlr.Contrato
						Z20->Z20_SLDCTR := ((Z20->Z20_VLRCTR +nAdtRece) - nAdtPaga)//Saldo Contr.
						Z20->Z20_USRALT := __CUSERID
						Z20->Z20_DATALT := Date()
						Z20->Z20_HORALT := Substr(Time(),1,5)
						Z20->Z20_OBSCTR := Z20->Z20_OBSCTR+ENTER+'Atualizado valor contrato após geração do romaneio de carga.'
						Z20->(MsUnlock())			
					EndIf
					*/
				Else
					RecLock('Z20',.F.)
					Z20->Z20_PESOBR	:= nQtdAtu
					Z20->Z20_PESOLI := nQtdAtu
					Z20->Z20_VLRFRE	:= nVlrAtu	
					Z20->Z20_VLRCTR := Z20->Z20_VLRFRE+Z20->Z20_VLRPED+Z20->Z20_VLRPER+Z20->Z20_VLRDES+Z20->Z20_VLRDPC+Z20->Z20_VLROUT//Vlr.Contrato
					Z20->Z20_SLDCTR := ((Z20->Z20_VLRCTR +nAdtRece) - nAdtPaga)//Saldo Contr.
					Z20->Z20_USRALT := __CUSERID
					Z20->Z20_DATALT := Date()
					Z20->Z20_HORALT := Substr(Time(),1,5)
					Z20->Z20_OBSCTR := Z20->Z20_OBSCTR+ENTER+'Atualizado valor contrato após geração do romaneio de carga.'
					Z20->(MsUnlock())	
				EndIF
			EndIF
		EndIF
	Else
		lRet := .F.
	EndIf

Return lRet

//Função para verificar o valor do GRIS a ser gerado
User Function fPsqInfo(cEmitent, cNrRoman, cCdPlaca)
	Local aAreaGW8	:= GetArea()
	Local lRet		:= .F.
	Local cTemGRIS	:= 'N'
	Local cTemADIA	:= 'N'

	DbSelectArea("GW1")
	GW1->(DbOrderNickName("ROMANEIO"))
	If GW1->(DbSeek(xFilial("GW1")+cNrRoman))
		cTipFret := GW1->GW1_TPFRET //1=CIF;2=CIF Redesp.;3=FOB;4=FOB Redesp.;5=Consignado;6=Consig. Redesp.
		IF Empty(cTipFret)
			cTipFret := "1"
		EndIF

		IF !Empty(cEmitent)
			DbSelectArea("GU3")
			GU3->(DbSetOrder(11))	
			If GU3->(MsSeek(FwxFilial("GU3") + cEmitent))
				lRet := .T.
				While GU3->(!EoF()) .AND. GU3->GU3_IDFED == cEmitent
					IF GU3->GU3_CLIEN == "1"
						cCdCliTra := GU3->GU3_CDERP
						cLjCliTra := GU3->GU3_CDCERP
					EndIF

					IF (GU3->GU3_TRANSP == "1" .Or. GU3->GU3_AUTON == "1")
						cCdForTrp	:= GU3->GU3_CDERP
						cLjForTrp	:= GU3->GU3_CDCERP
						cTemGRIS 	:= GU3->GU3_XGRIS
						cTemADIA	:= GU3->GU3_XADIAN
						cNmCliTra	:= GU3->GU3_NMEMIT
						cCdTransp	:= GU3->GU3_CDTERP
					EndIF

					GU3->(dbSkip())
				EndDo
			EndIf
		EndIF
	EndIF

	//Validar geração da GRIS
	lGeraGRIS := cTemGRIS == "S"
	nPercGris := IIF(lGeraGRIS .AND. !Empty(cTipVei), Posicione("Z24",1,xFilial('Z24')+cTipVei,"Z24_GRIS") , 0 )

	//Validar geração do Adiantamento
	lGeraADIA := cTemADIA == "S"
	nPercADIA := IIF(lGeraADIA, SUPERGETMV("ES_43ADPER", .T.,0,xFilial("GWN")), 0 )

	RestArea(aAreaGW8)

Return lRet

//Função para achar todos os adiantamentos que estão ligados aos contrato.
Static Function AchAdtFr(cTmpNum, cTmpPlc)
	Local cQuery	:= ""
	Local aRegSE2	:= {}
	Local aRetREG	:= {}	
	Local cPrefGRI	:= SuperGetMV("ES_43PXGRI"	,.F.,"")	//Prefixo do Titulo gerado para o GRIS

	IF !Empty(cTmpNum)
		cQuery := "SELECT SUM(PAGAR) PAGAR, SUM(RECEBER) RECEBER FROM ("
		cQuery += "SELECT SUM(E2_VALOR) PAGAR,  0 RECEBER "
		cQuery += "FROM "+RetSqlName('SE2')+" SE2 "
		cQuery += "WHERE " + RetSqlCond("SE2")+" "
		cQuery += "AND E2_TIPO NOT IN ('PR ','CH','CHF','CHP','CHR','NCC','NDF', 'ADI', 'ADF') "
		cQuery += "AND E2_TIPO NOT LIKE '__-' "
		cQuery += "AND E2_XCTRFRT	= '"+cTmpNum+"' "
		cQuery += " UNION ALL "
		cQuery += "SELECT SUM(E1_VALOR) PAGAR, 0 RECEBER "
		cQuery += "FROM "+RetSqlName('SE1')+" SE1 "
		cQuery += "WHERE " + RetSqlCond("SE1")+" "
		cQuery += "AND E1_TIPO NOT IN ('PR ','CH','CHF','CHP','CHR','NCC','NDF', 'ADI', 'ADF') "
		cQuery += "AND E1_TIPO NOT LIKE '__-' "
		cQuery += "AND E1_PREFIXO	!= '"+cPrefGRI+"' "
		cQuery += "AND E1_XCTRFRT	= '"+cTmpNum+"' "
		cQuery += " UNION ALL " //Tabela de Abastecimento
		cQuery += "SELECT SUM((Case Z23_TOTAL when 0 then Z23_VLRABA else  Z23_TOTAL end)) PAGAR, 0 RECEBER "
		cQuery += "FROM "+RetSqlName('Z23')+" Z23 "
		cQuery += "WHERE " + RetSqlCond("Z23")+" "
		cQuery += "AND Z23_CTRFRT	= '"+cTmpNum+"' "
		cQuery += "AND Z23_RECSE2	= ' ' "
		cQuery += "AND Z23_STATUS 	<> 'C' "
		cQuery += "AND Z23_PLACA	= '"+cTmpPlc+"' "
		cQuery += " UNION ALL " //Tabela de Lavagem
		cQuery += "SELECT SUM(Z22_VLRLAV) PAGAR, 0 RECEBER "
		cQuery += "FROM "+RetSqlName('Z22')+" Z22 "
		cQuery += "WHERE " + RetSqlCond("Z22")+" "
		cQuery += "AND Z22_CTRFRT	= '"+cTmpNum+"' "
		cQuery += "AND Z22_RECSE2	= ' ' "
		cQuery += "AND Z22_STATUS 	<> 'C' "
		cQuery += "AND Z22_PLACA	= '"+cTmpPlc+"' "
		cQuery += ") XXX "

		//MemoWrite("C:\TEMP\AchAdtFr.sql",cQuery)
		aRegSE2	:= ArrayQry(cQuery)

		IF Len(aRegSE2) > 0
			aadd(aRetREG, aRegSE2[1,1])
			aadd(aRetREG, aRegSE2[1,2])
		EndIF

	EndIF
Return aRetREG

//Função utilizada para retornar a quantidade da mercadoria associado ao Romaneio de Carga
User Function fQtdRom(cFilRom, cCodRom)
	Local aAreaGW8 := GetArea()
	Local nRet := 0
	Local cparcampo := SuperGetMV("ES_43CPMER"	,.F.,"1") //novo parametro usado para buscar qual o campo será usado na quantidade (peso liquido ou peso bruto ou quantidade)

	DbSelectArea("GW1") //GW1 - Documento de Carga
	GW1->(DbSetOrder(9))
	GW1->(DbSeek(xFilial("GW1")+cCodRom))
	Do While !GW1->( Eof() ) .and. GW1->GW1_FILIAL == xFilial("GW1") .and. 	GW1->GW1_NRROM == cCodRom 
		//If GW1->(DbSeek(xFilial("GW1")+cCodRom))
			DbSelectArea("GW8") //GW8 - Itens do Documento de Carga
			GW8->(DbSetOrder(1))
			GW8->( dbSeek(xFilial("GW8") + GW1->GW1_CDTPDC + GW1->GW1_EMISDC + GW1->GW1_SERDC + GW1->GW1_NRDC) )
		//	While !GW8->( Eof() ) .And. GW8->GW8_CDTPDC == GW1->GW1_CDTPDC .And. GW8->GW8_EMISDC == GW1->GW1_EMISDC .And. GW8->GW8_SERDC == GW1->GW1_SERDC .And. GW8->GW8_NRDC == GW1->GW1_NRDC
				If cparcampo == "1" .Or. Empty(cparcampo)
					nRet += GW8->GW8_QTDE
				ElseIf cparcampo == "2"
					nRet += GW8->GW8_PESOR
				ElseIf cparcampo == "3"
					nRet += GW8->GW8_PESOC
				EndIf
		//		GW8->(DbSkip())
		//	EndDo
		//EndIf
		GW1->(DbSkip())
	EndDo
	RestArea(aAreaGW8)
Return nRet

//Função para incluir contrato de frete
Static Function IncluiZ20(cFilRom,cCodRom,cPlaca,cCdMotor)
	Local lRet 		:= .T.
	Local cNmMoto	:= IIF(Empty(cCdMotor), "", Alltrim(POSICIONE("GUU",1,XFILIAL("GUU")+cCdMotor,"GUU_NMMTR")) )
	Local cCombpad	:= SuperGetMV("ES_43COMRO",.F.,'S10')
	Local lHabADT	:= SuperGetMV("ES_43HBADT",.F.,.F.)
	Local cTipoGRI	:= SuperGetMV("ES_43TPGRI"	,.F.,"")	//Tipo do Titulo gerado para o GRIS
	Local cPrefGRI	:= SuperGetMV("ES_43PXGRI"	,.F.,"")	//Prefixo do Titulo gerado para o GRIS
	Local cNatuGRI	:= SuperGetMV("ES_43NAGRI"	,.F.,"")	//Natureza do Titulo gerado para o GRIS	
	Local cTipoADT	:= SuperGetMV("ES_43TPAD"	,.F.,"")	//Tipo do Titulo gerado para o Adiantamento	 
	Local cPrefADT	:= SuperGetMV("ES_43PXAD"	,.F.,"")	//Prefixo do Titulo gerado para o Adiantamento
	Local cNatuADT	:= SuperGetMV("ES_43NATAD"	,.F.,"")	//Natureza do Titulo gerado para o Adiantamento
	Local nDiasADT	:= SuperGetMV("ES_43DDVAB"	,.F., 0)	//Quantidade de Dias do Vencimento para o Adiantamento
	Local nVlrGRI	:= IIF(lGeraGRIS .AND. nPercGris > 0, ROUND((nVlrMerca * (nPercGris/100)),2), 0)
	Local lCriaGR	:= !Empty(cCdCliTra) .AND. !Empty(cLjCliTra) .AND. nVlrGRI > 0	
	Local nVlrADI	:= IIF(lGeraADIA .And. nPercADIA > 0, ROUND((nVlrFrete * (nPercADIA/100)),2), 0)
	Local lCriaAD	:= !Empty(cCdCliTra) .AND. !Empty(cLjCliTra) .AND. nVlrADI > 0
	Local cMsgCTR	:= "Contrato automatico, sendo gerado a partir do calculo de frete x romaneio de carga."
	Local cTitulo	:= ""
	Local nVlrCtr	:= 0
	Local nVlrSld	:= 0
	Local nDiasGRI	:= SuperGetMV("ES_43DDVGR"	,.F., 10)	//Quantidade de Dias do Vencimento para o GRIS
	Local dVencGRI	:= DaySum(Date() , nDiasGRI )
	Local cHistGRI	:= "Vlr Mercadoria: "+Transform(nVlrGRI,"@E 999,999.99")+" | % Gris: "+cValtoChar(nPercGris)
	Local cHistADT	:= "Vlr Frete: "+Transform(nVlrADI,"@E 999,999.99")+" | % Adt: "+cValtoChar(nPercADIA)

	IF !lCriaGR
		cMsgCTR += "Transportador ( "+Alltrim(GWN->GWN_CDTRP)+" ) está com as configurações para não gerar financeiro(GRIS)."+ENTER
	EndIF
	IF !lCriaAD
		cMsgCTR += "Transportador ( "+Alltrim(GWN->GWN_CDTRP)+" ) está com as configurações para não gerar financeiro(Adiantamento)."+ENTER
	EndIF

	cNumCtrFR := GETSXENUM("Z20","Z20_CTRFRT")

	//Gravar o Abastecimento
	If nVlrADI > 0
		cNumABAS := GETSXENUM("Z23","Z23_REQABA")

		RecLock('Z23',.T.)
		Z23->Z23_FILIAL := cFilRom
		Z23->Z23_REQABA := cNumABAS
		Z23->Z23_CTRFRT := cNumCtrFR
		Z23->Z23_ROMFRT := cCodRom
		Z23->Z23_TRANSP := cCdTransp
		Z23->Z23_NMTRAN := cNmCliTra
		Z23->Z23_MOTOR  := cCdMotor
		Z23->Z23_NMOTO	:= cNmMoto
		Z23->Z23_PLACA  := Trim(cPlaca)
		Z23->Z23_STATUS := 'A'
		Z23->Z23_TIPABA := u_G0108605(Trim(cPlaca))
		Z23->Z23_TIPVEI := cTipVei 
		Z23->Z23_DSCVEI := Posicione("DUT", 1, xFilial("DUT") + cTipVei ,"DUT_DESCRI")
		Z23->Z23_CODCOM := cCombpad
		Z23->Z23_DESCOM := Posicione("TQM",1,xFilial("TQM")+cCombpad,"TQM_NOMCOM")
		Z23->Z23_VLRABA := nVlrADI
		Z23->Z23_DATVLD := DaySum(Date() , nDiasADT ) //Soma Dias em Uma Data
		Z23->Z23_OBSERV := 'Requisição automatica, sendo gerada a partir do calculo de frete x contrato de frete'+ENTER
		Z23->Z23_CENTRO := cCentro
		Z23->Z23_ITEMCT := cItemCent
		Z23->Z23_USRINC := __CUSERID
		Z23->Z23_DATINC := Date()
		Z23->Z23_HORINC := Substr(Time(),1,5)  
		If GWN->GWN_ORI == '2'
			Z23->Z23_CARGA := avKey(Substr(GWN->GWN_NRROM,1,TamSX3('Z23_CARGA')[1] ),'Z23_CARGA')
			Z23->Z23_SQCAR := avKey(Substr(GWN->GWN_NRROM,TamSX3('Z23_CARGA')[1]+1, Len(GWN->GWN_NRROM) ),'Z23_SQCAR')
		EndIf 
		Z23->(MsUnlock())
	EndIf

	nVlrCtr := nVlrFrete
	nVlrSld	:= (nVlrFrete - nVlrADI)

	//contrato de frete
	RecLock("Z20",.T.)
	Z20->Z20_FILIAL := cFilRom
	Z20->Z20_CTRFRT := cNumCtrFR
	Z20->Z20_ROMFRT := cCodRom
	Z20->Z20_PLACA  := cPlaca
	Z20->Z20_CTRTIP := 'A' //tipo M-Manual/A-Automatico
	Z20->Z20_TRANSP := cCdTransp
	Z20->Z20_NMTRAN := cNmCliTra
	Z20->Z20_MOTOR  := cCdMotor
	Z20->Z20_NMOTO	:= cNmMoto
	Z20->Z20_PESOBR	:= nQtRoman
	Z20->Z20_PESOLI := nQtRoman
	Z20->Z20_VLRFRE	:= nVlrFrete		//Valor Do Frete
	Z20->Z20_VLRPED := 0//Vlr Pedagio
	Z20->Z20_VLRPER := 0//Vlr.Pernoite
	Z20->Z20_VLRDES := 0//Vlr.Descarga
	Z20->Z20_VLRDPC := 0//Vlr.Despacho
	Z20->Z20_VLROUT := 0//Vlr.Outros
	Z20->Z20_VLRCTR := nVlrCtr//Vlr.Contrato
	Z20->Z20_SLDCTR := nVlrSld//Saldo Contr.
	Z20->Z20_TIPFRE := cTipFret 
	Z20->Z20_GRIS   := IIF(lGeraGRIS, "S", "N")
	Z20->Z20_PCGRIS := nPercGris
	Z20->Z20_ADIANT := IIF(lGeraADIA, "S", "N")
	Z20->Z20_PCADIA := nPercADIA
	Z20->Z20_STATUS := IIF(Z20->Z20_VLRFRE == Z20->Z20_VLRCTR, 'A','P') //A=Aberto C=Cancelado P=Parcial T=Total F=Finalizado   {necessita definição}
	Z20->Z20_CENTRO := cCentro //necessita definição
	Z20->Z20_ITEMCT := cItemCent //necessita definição
	Z20->Z20_OBSCTR := cMsgCTR
	Z20->Z20_USRINC := __CUSERID
	Z20->Z20_DATINC := Date()
	Z20->Z20_HORINC := Substr(Time(),1,5)
	Z20->(MsUnLock())	

	//Efetuar a inclusão do GRIS no Financeiro
	IF lCriaGR
		cTitulo := 	"Prefixo: "+cPrefGRI+" Nr.Titulo: "+cNumCtrFR+" Parcela: "+PadR('1',TamSX3("E1_PARCELA")[1])+" Tipo: "+cTipoGRI+" Natureza: "+cNatuGRI

		IF U_fExitTit("SE1", cPrefGRI, cNumCtrFR, PadR('1',TamSX3("E1_PARCELA")[1]), cTipoGRI, cNatuGRI)
			IF lMstMsg
				U_fMsgHelp(,"Já existe um lançamento de GRIS ativo no financeiro para este contrato.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o lançamento de GRIS no financeiro. "+cTitulo})
			Else
				U_fCriaMSG("Help [G0108642] -> Já existe um lançamento de GRIS ativo no financeiro para este contrato.")
			EndIF
		Else
			U_fInclFin(cPrefGRI, cNumCtrFR, PadR('1',TamSX3("E1_PARCELA")[1]), cTipoGRI, cNatuGRI, cCdCliTra, cLjCliTra, nVlrGRI, dVencGRI, cHistGRI, cCentro, cItemCent, cNumCtrFR)
		EndIF
	EndIF	

	//Efetuar a inclusão do Adiantamento no financeiro
	IF lCriaAD .AND. lHabADT
		cTitulo := 	"Prefixo: "+cPrefADT+" Nr.Titulo: "+cNumABAS+" Parcela: "+PadR('1',TamSX3("E1_PARCELA")[1])+" Tipo: "+cTipoADT+" Natureza: "+cNatuADT

		IF U_fExitTit("SE1", cPrefADT, cNumCtrFR, PadR('1',TamSX3("E1_PARCELA")[1]), cTipoADT, cNatuADT)
			IF lMstMsg
				U_fMsgHelp(,"Já existe um lançamento de ADIANTAMENTO ativo no financeiro para este contrato.", "Verifique o lançamento de ADIANTAMENTO no financeiro. "+cTitulo)
			Else
				U_fCriaMSG("Help [G0108642] -> Já existe um lançamento de ADIANTAMENTO ativo no financeiro para este contrato.")
			EndIF
		Else
			IF U_fInclFin(cPrefADT, cNumABAS, PadR('1',TamSX3("E1_PARCELA")[1]), cTipoADT, cNatuADT, cCdCliTra, cLjCliTra, nVlrADI, dVencGRI, cHistADT, cCentro, cItemCent, cNumCtrFR)	
				U_CalcSld(cNumCtrFR, .T.)
				ValRomCtr(GWN->GWN_FILIAL,GWN->GWN_NRROM, nVlrFrete, nQtRoman, .T.)
			EndIF
		EndIF
	EndIF		

Return lRet 

//Função para Achar o Valor do Frete
User Function fVlrFrt(cCodRom)
	Local aAreaFrt	:= GetArea()
	Local nVlFrete	:= 0
	Local nVlTotAj	:= 0
	Local nVlFinal	:= 0
	Local cQuery	:= ""
	Local aRetGWF	:= {}
	Local nCount	:= 0
	Local lImpEmbut	:= .F.
	Local nImpValor	:= 0
	Local nImpAliqu	:= 0
	Local cNrCalcul	:= ""
	Default cFilRom	:= ""

	cQuery := "SELECT DISTINCT GWF_NRCALC "//,GWF_TPCALC,GWF_DTCRIA,GU3_NMEMIT "
	cQuery += "FROM "+RetSqlName('GWF')+" GWF "
	cQuery += "INNER JOIN "+RetSqlName('GU3')+" GU3 ON GU3.GU3_FILIAL = '"+xFilial('GU3')+"' "
	cQuery += "		AND GU3.GU3_CDEMIT = GWF.GWF_TRANSP "
	cQuery += "		AND GU3.D_E_L_E_T_ = ' ' "
	cQuery += "WHERE GWF.GWF_FILIAL = '"+xFilial('GWF')+"' "
	cQuery += "AND GWF.GWF_NRROM  = '"+cCodRom+"' "
	cQuery += "AND GWF.GWF_TPCALC <> '8' " // 8 - Estimativa
	cQuery += "AND GWF.D_E_L_E_T_ = ' '"

	aRetGWF	:= ArrayQry(cQuery)

	IF Len(aRetGWF) > 0
		dbSelectArea("GWF")
		GWF->(dbSetOrder(1))

		dbSelectArea("GWI")
		GWI->(dbSetOrder(1))

		dbSelectArea("GWO")
		GWO->(dbSetOrder(1))

		For nCount:=1 To  Len(aRetGWF)

			cNrCalcul := aRetGWF[nCount,1]

			If GWF->( dbSeek(xFilial("GWF") + cNrCalcul ) )

				IF GWF->GWF_ADICIS == "1"
					lImpEmbut := .T.
					If GWF->GWF_IMPOST == "1"	// ICMS
						nImpValor	:= GWF->GWF_VLICMS
						nImpAliqu	:= GWF->GWF_PCICMS
					Else						// ISS
						nImpValor	:= GWF->GWF_VLISS
						nImpAliqu	:= GWF->GWF_PCISS
					EndIf
				EndIf

				GWI->(dbSeek(xFilial("GWI") + GWF->GWF_NRCALC))
				While GWI->(!Eof()) .AND. xFilial("GWI") == GWI->GWI_FILIAL .AND. GWI->GWI_NRCALC == GWF->GWF_NRCALC
					If GWI->GWI_TOTFRE == "1"
						nVlFrete += GWI->GWI_VLFRET
					EndIf
					GWI->(dbSkip())
				EndDo

				GWO->(dbSeek(xFilial("GWO")+GWF->GWF_NRCALC ))
				While !Eof() .AND. xFilial("GWO") == GWO->GWO_FILIAL .AND. GWO->GWO_NRCALC == GWF->GWF_NRCALC
					//Soma o valor dos ajustes ja realizados
					If GWO->GWO_SITAJU <> "3"
						nVlTotAj += GWO->GWO_VLAJUS
					EndIf
					GWO->(dbSkip())
				EndDo

			EndIf

			If lImpEmbut
				nVlFinal += (nVlFrete - nImpValor) + nVlTotAj
				nVlFinal += NoRound(nVlFinal / ((100 - nImpAliqu) / 100), 2)
			Else
				nVlFinal += nVlFrete + nVlTotAj
			EndIf

			lImpEmbut	:= .F.
			nVlFrete	:= 0
			nImpAliqu	:= 0
			nVlTotAj	:= 0

		Next nCount
	EndIF

	RestArea(aAreaFrt)

return nVlFinal


//Função para retornar um array a partir de uma query
Static Function ArrayQry(cQuery)
	Local aRet    := {}
	Local aRet1   := {}
	Local nRegAtu := 0
	Local x       := 0

	cQuery := ChangeQuery(cQuery)
	TCQUERY cQuery NEW ALIAS "_TRB"

	dbSelectArea("_TRB")
	aRet1   := Array(Fcount())
	nRegAtu := 1

	While !Eof()

		For x:=1 To Fcount()
			aRet1[x] := FieldGet(x)
		Next
		Aadd(aRet,aclone(aRet1))

		dbSkip()
		nRegAtu += 1
	Enddo

	dbSelectArea("_TRB")
	_TRB->(DbCloseArea())

Return(aRet)
