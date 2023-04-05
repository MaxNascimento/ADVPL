#Include "Protheus.ch"

/*{Protheus.doc} F0400160
//P04001 - GAP097 – Automatização Emissão NF Triangular (Agro)_V01
@type 		Function 
@author 	Sergio Compain
@since 		09/08/2019
@version 	P12.1.23
@project	0000032563
@history 	09/08/2019, Sergio Compain, Desenvolvimento inicial (MIT044 P04001 - GAP097 – Automatização Emissão NF Triangular (Agro)_V01) - Geração Nota de Remessa

Chamado 143679 - Juliano Fregadolli - Problema na validação da nota e impressao
*/

User Function F0400160(oTxtProc,oMeterPrc)
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
    Local nX
	Private lMsErroAuto := .F.

	cFilAnt := aDadosOper[10]
	U_F07ChkFil(aDadosOper[10])

	SC5->( DbSetOrder(1) ) // C5_FILIAL + C5_NUM

	If !Empty(PDB->PDB_PED2) .and. SC5->( DbSeek( aDadosOper[10] + PDB->PDB_PED2 ) ) // se o pedido ainda não foi gerado
		oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Geração o Pedido de Remessa ........["+SC5->C5_NUM+"]  [OK]" +pLinha )
		oTxtProc:Refresh()
		aNotasOper[6] := SC5->C5_NUM
	Else
		aadd(aCabec, {"C5_FILIAL" , aDadosOper[10]      , Nil})
		aadd(aCabec, {"C5_TIPO"   , "B"                 , Nil})
		aadd(aCabec, {"C5_CLIENTE", aDadosOper[11]      , Nil})
		aadd(aCabec, {"C5_LOJACLI" , aDadosOper[12]     , Nil})
		aadd(aCabec, {"C5_CONDPAG", aDadosOper[14]      , Nil})
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

		aadd(aLinha, {"C6_FILIAL" , aDadosOper[10]       , Nil})
		aadd(aLinha, {"C6_ITEM"   , STRZERO(++nSeqItem,TAMSX3("C6_ITEM")[1]) , Nil})
		aadd(aLinha, {"C6_PRODUTO", aDadosOper[26]      , Nil})
		aadd(aLinha, {"C6_QTDVEN" , aDadosOper[28]      , Nil})
		aadd(aLinha, {"C6_QTDLIB" , aDadosOper[28]      , Nil})
		aadd(aLinha, {"C6_PRCVEN" , aDadosOper[29]      , Nil})
		aadd(aLinha, {"C6_LOCAL"  , aDadosOper[31]      , Nil})
		aadd(aLinha, {"C6_TES"    , aDadosOper[13]       , Nil})
		aadd(aLinha, {"C6_XLTAV"  , aDadosOper[32]      , Nil})
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

			oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Geração o Pedido de Remessa ........[ERRO]" +pLinha )
			oTxtProc:Refresh()
			lPed := .f.
		Else
			oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Geração o Pedido de Remessa ........["+SC5->C5_NUM+"]  [OK]" +pLinha )
			oTxtProc:Refresh()
			aNotasOper[6] := SC5->C5_NUM

			RecLock("pdb", .F.)	
				PDB->PDB_PED2 := SC5->C5_NUM
			PDB->( MsUnlock() )
		EndIf
	Endif

	oMeterPrc:Set(7)
	oMeterPrc:Refresh()

	If Empty(PDB->PDB_NFS2) // se a NF de remessa não foi gerada
		If lPed
			cNumPed := SC5->C5_NUM
			//Verifica a liberacao do Pedido     
			Ma410LbNfs(2,@aPvlNfs,@aBloqueio)

			If !Empty(aBloqueio)
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Liberação do Pedido de Remessa .......["+cNumPed+"]  [BLOQUEADO] "+pLinha )
				lPed := .f.

				RecLock("pdb", .F.)	
					PDB->PDB_LIBPD2 := "N"
				PDB->( MsUnlock() )
			Else    
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Liberação o Pedido de Remessa .......["+cNumPed+"]  [OK] "+pLinha )

				RecLock("pdb", .F.)	
					PDB->PDB_LIBPD2 := "S"
				PDB->( MsUnlock() )
			EndIf    
			oTxtProc:Refresh()

		EndIf

		oMeterPrc:Set(8)
		oMeterPrc:Refresh()

		If lPed 
			If SC6->(DbSeek(xFilial("SC6") + cNumPed))
				cLtAv	:= SC6->C6_XLTAV			
				While SC6->C6_FILIAL + SC6->C6_NUM == SC5->C5_FILIAL + SC5->C5_NUM .And. SC6->(!Eof())
					SB1->(DbSetOrder(1))
					SB1->(DbSeek(xFilial("SB1") + SC6->C6_PRODUTO))
					SB2->(DbSetOrder(1))
					SB2->(DbSeek(xFilial("SB2") + SC6->C6_PRODUTO))
					SF4->(DbSetOrder(1))
					SF4->(DbSeek(xFilial("SF4") + SC6->C6_TES))
					
					AAdd(aPvlNfs,{SC6->C6_NUM ,;	//[01]
					SC6->C6_ITEM 		,;	//[02]
					SC6->C6_LOCAL 	,;	//[03]
					SC6->C6_QTDVEN 	,;	//[04]
					SC6->C6_VALOR 	,;	//[05]
					SC6->C6_PRODUTO	,;	//[06]
					.F. 				,;	//[07]
					SC9->(RECNO())	,;	//[08]
					SC5->(RECNO()) 	,;	//[09]
					SC6->(RECNO()) 	,;	//[10]
					SE4->(RECNO())	,;	//[11]
					SB1->(RECNO())	,;	//[12]
					SB2->(RECNO())	,;	//[13]
					SF4->(RECNO())	}) 	//[14]
					SC6->(DbSkip())
				Enddo
				SC6->(DbSeek(xFilial("SC6") + SC5->C5_NUM))
			EndIf

			// Efetuo o faturamento do Pedido 
			Pergunte("MT460A", .F.)
			cNFSaida := MaPvlNfs(aPvlNfs, aDadosOper[15], .F., .F., .T., .T., .F., 0, 0, .T., .F.)

			If Empty(cNFSaida) .Or. cNFSaida == ""
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Emissao Nota do Pedido de Remessa .......[ERRO] "+pLinha )
				lPed := .f.
			Else
				RecLock("PDB", .F.)
					PDB->PDB_NFS2	:= cNFSaida
					PDB->PDB_SNFS2	:= aDadosOper[15]
				PDB->( MsUnLock() )

				If !Empty(cLtAv)
					For nX := 1 To Len(aPvlNfs)
						DbSelectArea("SFT")
						SFT->(DbSetOrder(1))
						If SFT->(DbSeek(xFilial("SFT")+ 'S' + aDadosOper[15] + cNFSaida + SC5->C5_CLIENTE + SC5->C5_LOJACLI + aPvlNfs[nX][2]) )
							RecLock("SFT",.F.)
							SFT->FT_XLTAV   := cLtAv
							SFT->(MsUnlock())						
						EndIf
					Next nX 
				EndIf		

				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Emissao Nota do Pedido de Remessa .......["+cNFSaida+"]  [OK] "+pLinha )
				aNotasOper[7] := aDadosOper[15]
				aNotasOper[8] := cNFSaida

				SF2->(Reclock("SF2",.F.))
					SF2->F2_XIDOPT := aNotasOper[1]
				SF2->(Msunlock())
			EndIf

			oTxtProc:Refresh()
		EndIf
	Else
		cNumPed := SC5->C5_NUM
		oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Liberação do Pedido de Remessa .......["+cNumPed+"]  [OK] "+pLinha )
		oTxtProc:Refresh()
		oMeterPrc:Set(8)
		oMeterPrc:Refresh()

		cNFSaida := PDB->PDB_NFS2
		oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Emissao Nota do Pedido de Remessa .......["+cNFSaida+"]  [OK] "+pLinha )
		oTxtProc:Refresh()
		aNotasOper[7] := aDadosOper[15]
		aNotasOper[8] := cNFSaida

		SF2->( DbSetOrder(1) ) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
		SD2->( dbSetOrder(3) ) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM

		SF2->( DbSeek( xFilial("SF2")+cNFSaida+aDadosOper[6]+aDadosOper[11]+aDadosOper[12] ) )
		SD2->( DbSeek( xFilial("SD2")+cNFSaida+aDadosOper[6]+aDadosOper[11]+aDadosOper[12] ) )
	Endif

	cNFRemesA := cNFSaida

	oMeterPrc:Set(9)
	oMeterPrc:Refresh()

    
	If lPed 
		If Empty(PDB->PDB_CHV2)
			If Empty(SF2->F2_CHVNFE)	

				aAreaSF2 := SF2->(getArea())
				
				//transmite as notas geradas
				nConsulta	 := 0
				//AutoNfeEnv(cEmpAnt,cFilAnt,"0","1",aDadosOper[15],cNFSaida,cNFSaida)

				//--------------------
				//Transmissão da Nfe
				//--------------------
				U_F040013A(aDadosOper[15], cNFSaida, cNFSaida )
				restArea(aAreaSF2)
					

				//--------------------
				//Monitoramento da Nfe
				//--------------------
				U_F0400190(aDadosOper[15],cNFSaida)
				restArea(aAreaSF2)

				aSize(aAreaSF2,0)

			Endif
			
			If Empty(SF2->F2_CHVNFE)	
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Transmissao Nota de Remessa .......["+cNFSaida+"]  [ERRO] "+pLinha )
				lPed := .f.
			Else	
				oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Transmissao Nota de Remessa .......["+cNFSaida+"]  [OK] "+pLinha )
				aNotasOper[9] := SF2->F2_CHVNFE

				RecLock("PDB", .F.)
					PDB->PDB_CHV2 := SF2->F2_CHVNFE
				PDB->( MsUnLock() )
			EndIf
		Else
			oTxtProc:AppendText( OEMToANSI(FWTimeStamp(2)) + " - Transmissao Nota de Remessa .......["+cNFSaida+"]  [OK] "+pLinha )
			aNotasOper[9] := SF2->F2_CHVNFE
		Endif
		oTxtProc:Refresh()
	EndIf

	If !lPed 
		lProc := .f.
	EndIf

    U_F07ChkFil(aDadosOper[2])

    oMeterPrc:Set(10)
	oMeterPrc:Refresh()
Return(lProc)

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
