#Include "Protheus.ch"

/*{Protheus.doc} F0400130
//P04001 - GAP097 – Automatização Emissão NF Triangular (Agro)_V01
@type 		Function 
@author 	Sergio Compain
@since 		29/07/2019
@version 	P12.1.23
@project	0000032563
// 02/06/2020
@history 	29/07/2019, Sergio Compain, Desenvolvimento inicial (MIT044 P04001 - GAP097 – Automatização Emissão NF Triangular (Agro)_V01) - Geração Nota de transferencia

Chamado 143679 - Juliano Fregadolli - Problema na validação da nota e impressao
*/

User Function F0400130(oTxtProc,oMeterPrc,aSD2Itens)
	Local pLinha	:= chr(13)+chr(10)
	Local aCabec    := {}
	Local aLinha    := {}
	Local aItens    := {}
	Local nSeqItem 	:= 0
	Local lPed      := .t.
	Local lProc     := .t.
	Local cNumPed   := ""
	Local cLtAv		:= ""
	Local aPvlNfs	:= {}
	Local aBloqueio	:= {{"","","","","","","",""}}
	Local cNFSaida  := ""
	Local cChave    := ""
	Local nConsulta := 0
	Local nX
	Private lMsErroAuto := .F.

	cFilAnt := aDadosOper[2]
	U_F07ChkFil(cFilAnt)

	SC5->( DbSetOrder(1) ) // C5_FILIAL + C5_NUM

	If !Empty(PDB->PDB_PED1) .and. SC5->( DbSeek( aDadosOper[2] + PDB->PDB_PED1 ) ) // se o pedido ainda não foi gerado
		oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Geração do Pedido de Transferencia .......["+SC5->C5_NUM+"]  [OK]" +pLinha )
		oTxtProc:Refresh()
		aNotasOper[2] := SC5->C5_NUM
	Else
		aadd(aCabec, {"C5_FILIAL" , aDadosOper[2]       , Nil})
		aadd(aCabec, {"C5_TIPO"   , "N"                 , Nil})
		aadd(aCabec, {"C5_CLIENTE", aDadosOper[7]       , Nil})
		aadd(aCabec, {"C5_LOJACLI" , aDadosOper[8]      , Nil})
		aadd(aCabec, {"C5_CONDPAG", aDadosOper[5]       , Nil})
		If !Empty(aDadosOper[36])
			aadd(aCabec, {"C5_TRANSP" , aDadosOper[36]      , Nil})
		EndIf
		If !Empty(aDadosOper[37])
			aadd(aCabec, {"C5_VEICULO" , aDadosOper[37]      , Nil})
		EndIf
		If !Empty(aDadosOper[38])
			aadd(aCabec, {"C5_XCDMOT" , aDadosOper[38]      , Nil})
		EndIf
		If !Empty(aDadosOper[32])
			aadd(aCabec, {"C5_MENNOTA", "Lote Aviario : "+ aDadosOper[32]  , Nil})
		EndIf

		aadd(aLinha, {"C6_FILIAL" , aDadosOper[2]       , Nil})
		aadd(aLinha, {"C6_ITEM"   , STRZERO(++nSeqItem,TAMSX3("C6_ITEM")[1]) , Nil})
		aadd(aLinha, {"C6_PRODUTO", aDadosOper[26]      , Nil})
		aadd(aLinha, {"C6_QTDVEN" , aDadosOper[28]      , Nil})
		aadd(aLinha, {"C6_QTDLIB" , aDadosOper[28]      , Nil})
		aadd(aLinha, {"C6_PRCVEN" , aDadosOper[29]      , Nil})
		aadd(aLinha, {"C6_LOCAL"  , aDadosOper[31]      , Nil})
		aadd(aLinha, {"C6_TES"    , aDadosOper[4]       , Nil})
		aadd(aItens, aLinha)

		MSExecAuto({|x,y,z|mata410(x,y,z)}, aCabec, aItens, 3)

		If lMsErroAuto
			if (!isblind()) // COM INTERFACE GRÁFICA
				MostraErro()
			else // EM ESTADO DE JOB
				//Mensagem de erro do execauto
				cArqLog   	:= GetNextAlias()+".log"
				cMsgErro 	:=  MostraErro(cLogPath,cArqLog)

				//Apaga o arquivo de LOG.
				if file(cLogPath+"\"+cArqLog)
					FErase(cLogPath+"\"+cArqLog)
				endif
			endif
			oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Geração do Pedido de Transferencia .......[PROCESSANDO]" +pLinha )
			oTxtProc:Refresh()
			lPed := .f.
		Else
			oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Geração do Pedido de Transferencia .......["+SC5->C5_NUM+"]  [OK]" +pLinha )
			oTxtProc:Refresh()
			aNotasOper[2] := SC5->C5_NUM

			RecLock("PDB", .F.)
			PDB->PDB_PED1 := SC5->C5_NUM
			PDB->( MsUnLock() )
		EndIf
	Endif

	oMeterPrc:Set(2)
	oMeterPrc:Refresh()

	If Empty(PDB->PDB_NFS1) // se a NF de transferência não foi gerada
		If lPed

			cNumPed := SC5->C5_NUM
			//Verifica a liberacao do Pedido
			Ma410LbNfs(1,@aPvlNfs,@aBloqueio) //Ajustado a liberação para item sem estoque ID 1034 FSW - Ronaldo Dantas - 10/12/2020

			If !Empty(aBloqueio)
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Liberação do Pedido de Transferencia .......["+cNumPed+"]  [BLOQUEADO] "+pLinha )
				lPed := .f.

				RecLock("PDB", .F.)
				PDB->PDB_LIBPD1 := "N"
				PDB->( MsUnLock() )
			Else
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Liberação do Pedido de Transferencia .......["+cNumPed+"]  [OK] "+pLinha )

				RecLock("PDB", .F.)
				PDB->PDB_LIBPD1 := "S"
				PDB->( MsUnLock() )
			EndIf
			oTxtProc:Refresh()

		EndIf

		oMeterPrc:Set(3)
		oMeterPrc:Refresh()

		If lPed
			If SC6->(DbSeek(xFilial("SC6") + cNumPed))
				cLtAv	:= SC6->C6_XLTAV
				//Ajustado a liberação para item sem estoque ID 1034 FSW - Ronaldo Dantas - 10/12/2020
				If Len(aPvlNfs) == 1
					aPvlNfs := {}
				EndIf

				While SC6->C6_FILIAL + SC6->C6_NUM == SC5->C5_FILIAL + SC5->C5_NUM .And. SC6->(!Eof())
					SB1->(DbSetOrder(1))
					SB1->(DbSeek(xFilial("SB1") + SC6->C6_PRODUTO))
					SB2->(DbSetOrder(1))
					SB2->(DbSeek(xFilial("SB2") + SC6->C6_PRODUTO))
					SF4->(DbSetOrder(1))
					SF4->(DbSeek(xFilial("SF4") + SC6->C6_TES))

					AAdd(aPvlNfs,{SC6->C6_NUM     ,;	//aPvlnfs[01] - Numero do Pedido de Venda
					SC6->C6_ITEM 	  ,;	//aPvlnfs[02] - Item do Pedido de Venda
					SC6->C6_LOCAL   ,;	//aPvlnfs[03] - Sequencia de Liberacao
					SC6->C6_QTDVEN  ,;	//aPvlnfs[04] - Quantidade Liberada
					SC6->C6_VALOR   ,;	//aPvlnfs[05] - Preco de Venda
					SC6->C6_PRODUTO ,;	//aPvlnfs[06] - Codigo do Produto
					.F. 			  ,;	//aPvlnfs[07] - TES com ISS
					SC9->(RECNO())  ,;	//aPvlnfs[08] - Recno do SC9
					SC5->(RECNO())  ,;	//aPvlnfs[09] - Recno do SC5
					SC6->(RECNO())  ,;	//aPvlnfs[10] - Recno do SC6
					SE4->(RECNO())  ,;	//aPvlnfs[11] - Recno do SE4
					SB1->(RECNO())  ,;	//aPvlnfs[12] - Recno do SB1
					SB2->(RECNO())  ,;	//aPvlnfs[13] - Recno do SB2
					SF4->(RECNO())  ,; 	//aPvlnfs[14] - Recno do SF4
					SC6->C6_LOCAL   ,;	//aPvlnfs[15] - Deposito
					0               ,;	//aPvlnfs[16] - Recno do DAK (Não usado)
					SC6->C6_UNSVEN})		//aPvlnfs[17] - Quantidade Liberada 2 UN

					SC6->(DbSkip())
				Enddo
				SC6->(DbSeek(xFilial("SC6") + SC5->C5_NUM))
			EndIf

			// Efetuo o faturamento do Pedido
			Pergunte("MT460A", .F.)

			oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Emissao Nota do Pedido de Transferencia .......[GERAÇÃO] "+pLinha )
			cNFSaida := MaPvlNfs(aPvlNfs, aDadosOper[6], .F., .F., .T., .T., .F., 0, 0, .T., .F.)

			If Empty(cNFSaida) .Or. cNFSaida == ""
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Emissao Nota do Pedido de Transferencia .......[NAO GERADA] "+pLinha )
				lPed := .f.
			Else 
				RecLock("PDB", .F.)
				PDB->PDB_NFS1	:= cNFSaida
				PDB->PDB_SNFS1	:= aDadosOper[6]
				PDB->( MsUnLock() )

				If !Empty(cLtAv)
					For nX := 1 To Len(aPvlNfs)
						DbSelectArea("SFT")
						SFT->(DbSetOrder(1))
						If SFT->(DbSeek(xFilial("SFT")+ 'S' + aDadosOper[6] + cNFSaida + SC5->C5_CLIENTE + SC5->C5_LOJACLI + aPvlNfs[nX][2]) )
							RecLock("SFT",.F.)
							SFT->FT_XLTAV   := cLtAv
							SFT->(MsUnlock())
						EndIf

					Next nX
				EndIf
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Emissao Nota do Pedido de Transferencia .......["+cNFSaida+"]  [OK] "+pLinha )
				aNotasOper[3] := aDadosOper[6]
				aNotasOper[4] := cNFSaida
				SF2->(Reclock("SF2",.F.))
				SF2->F2_XIDOPT := aNotasOper[1]
				SF2->(Msunlock())

				aSD2Itens := {} // para ser usado na NF de Entrada (F0400150)
				SD2->( dbSetOrder(3) ) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
				
				If SD2->( DbSeek(xFilial("SD2")+cNFSaida+aDadosOper[6]+aDadosOper[7]+aDadosOper[8]) )
					Do While SD2->( !Eof() ) .and.;
							SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == (xFilial("SD2")+cNFSaida+aDadosOper[6]+aDadosOper[7]+aDadosOper[8])

						aadd(aSD2Itens,{SD2->D2_ITEM	,;	// 01
						SD2->D2_COD		,;	// 02
						SD2->D2_QUANT	,;	// 03
						SD2->D2_PRCVEN	,;	// 04
						SD2->D2_TOTAL	,;	// 05
						SD2->D2_LOCAL	,;	// 06
						SD2->D2_LOTECTL	,;	// 07
						SD2->D2_NUMLOTE ,;	// 08
						SD2->D2_DTVALID ;	// 09
						})

						SD2->( DbSkip() )
					EndDo
				Endif
			EndIf
			oTxtProc:Refresh()
		EndIf
	Else
		cNumPed := SC5->C5_NUM
		oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Liberação do Pedido de Transferencia .......["+cNumPed+"]  [OK] "+pLinha )
		oTxtProc:Refresh()
		oMeterPrc:Set(3)
		oMeterPrc:Refresh()

		cNFSaida := PDB->PDB_NFS1
		oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Emissao Nota do Pedido de Transferencia .......["+cNFSaida+"]  [OK] "+pLinha )
		oTxtProc:Refresh()
		aNotasOper[3] := aDadosOper[6]
		aNotasOper[4] := cNFSaida

		SF2->( DbSetOrder(1) ) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
		SD2->( dbSetOrder(3) ) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM

		SF2->( DbSeek( xFilial("SF2")+cNFSaida+aDadosOper[6]+aDadosOper[7]+aDadosOper[8] ) )
		SD2->( DbSeek( xFilial("SD2")+cNFSaida+aDadosOper[6]+aDadosOper[7]+aDadosOper[8] ) )
	Endif

	cNFTrans := cNFSaida

	oMeterPrc:Set(4)
	oMeterPrc:Refresh()

	If lPed
		While .T.
			nConsulta++
			Sleep(10000)

			If Empty(SF2->F2_CHVNFE)	
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Verificando assinatura da nota .......["+SF2->F2_DOC+"]  ["+ STR(nConsulta) +"] "+pLinha )

				aAreaSF2 := SF2->(getArea())
				
				//--------------------
				//Transmissão da Nfe
				//--------------------
				U_F040013A(aDadosOper[21], cNFSaida, cNFSaida )
				restArea(aAreaSF2)

			
				//Monitoramento da Nfe
				U_F0400190(aDadosOper[21],SF2->F2_DOC)
				restArea(aAreaSF2)

				aSize(aAreaSF2,0)

				cQuery := "SELECT A.DOC_CHV "
				cQuery += "  FROM TSSPROD.SPED050 A"
				cQuery += "  WHERE A.NFE_ID = '" + SF2->F2_SERIE + SF2->F2_DOC + "'"
				cQuery += "    AND A.DATE_NFE = '" + DTOS(SF2->F2_EMISSAO) + "'"

				cQuery := ChangeQuery(cQuery)
				cAliasQry := MPSysOpenQuery(cQuery)

				If !(cAliasQry)->(Eof()) 
					cChave := (cAliasQry)->DOC_CHV
					Exit
				End If

				If nConsulta > 50
					oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Validação da Nota de Transferencia .......["+cNFSaida+"]  [SEM RETORNO SEFAZ] "+pLinha )
					lProc := .F.
					Exit
				EndIf
			Else 
				cChave := SF2->F2_CHVNFE
				Exit
			End If
		EndDo

		If !Empty(cChave)
			oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Transmissao Nota de Transferencia .......["+cNFSaida+"]  [OK] "+pLinha )
			aNotasOper[5] := SF2->F2_CHVNFE

			RecLock("PDB", .F.)
			PDB->PDB_CHV1 := SF2->F2_CHVNFE
			PDB->( MsUnLock() )

			lProc := .T.
		Endif

	Else
		oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Transmissao Nota de Transferencia .......["+cNFSaida+"]  [ERRO] "+pLinha )
		lProc := .F.
		
	EndIf

	oMeterPrc:Set(5)
	oMeterPrc:Refresh()
Return(lProc)

/*/{Protheus.doc} F040013A
Transmissão de NF de saída
@type function
@version  1.0
@author marcio.katsumata
@since 16/02/2022
@param cSerie, character, Série
@param cNotaIni, character, Nota fiscal inicial
@param cNotaFim, character, Nota fiscal final
@param cModelo, character, Modelo
@return logical, ok?
/*/
user function F040013A(cSerie, cNotaIni, cNotaFim,cModelo )

	local lOk			as logical
	local cAmbiente		as character
	local cModalidade	as character
	local cVersao		as character
	local lCte			as logical
	local lEnd			as logical
	local cError		as character
	local oDoc          as object
	local lUsaColab		as logical

	default cModelo := "55"
	lOk			:= .T.
	cAmbiente	:= ""
	cModalidade	:= ""
	cVersao		:= ""
	lCte		:= ( cModelo == "57" )
	lEnd		:= .F.
	cError		:= ""
	lUsaColab	:= UsaColaboracao("1")
	cIdEnt		:= if(lUsaColab, "000000", getCfgEntidade())
	
	// Inicio do processo de transmissao
	If !empty(cSerie) .and. !empty(cNotaIni) .and. !empty(cNotaFim) .and. !Empty( cIdEnt )
		// TOTVS Colaboracao 2.0
		If lUsaColab

			oDoc 			:= ColaboracaoDocumentos():new()
			oDoc:cModelo 	:= IIF(lCte,"CTE","NFE")
			oDoc:cTipoMov	:= "1"
			cAmbiente		:= ColGetPar("MV_AMBIENT","")
			cModalidade	    := ColGetPar("MV_MODALIDAD","")
			cVersao 		:= IIF(lCte,ColGetPar("MV_VERCTE","2.00"),ColGetPar("MV_VERSAO","3.10"))

			cRetorno := SpedNFeTrf("SF2",cSerie,cNotaIni,cNotaFim,cIdEnt,cAmbiente,cModalidade,cVersao,@lEnd,lCte,.T.,nil,nil)

		Else
			// TSS
			If !Empty( cIdEnt )

				cAmbiente := getCfgAmbiente(@cError, cIdEnt, cModelo)

				if( !empty(cAmbiente))

					cModalidade := getCfgModalidade(@cError, cIdEnt, cModelo)

					if( !empty(cModalidade) )
						cVersao	:= getCfgVersao(@cError, cIdEnt, cModelo)

						lOk := !empty(cVersao)

					endif
				endif

				if( lOk )
					cRetorno := SpedNFeTrf("SF2",cSerie,cNotaIni,cNotaFim,cIdEnt,cAmbiente,cModalidade,cVersao,@lEnd,lCte,.T.,nil,nil)
					conout(cRetorno)
				else
					if !Empty( cError )
						lOk := .F.
					endif
				endif
			endif
		endif
	endif
return lOk

Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)

	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL

	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10)
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "002.0   MAX NASCIMENTO      146183  07/03/23 " + CHR(10) //Ajuste da transmissão da nota 
	cTexto += "001.0   FREGADOLLI          143679  15/07/22 " + CHR(10) //Ajuste impressao e validacao nota 
	@ 10,70 SAY oSay PROMPT "F0403712" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
