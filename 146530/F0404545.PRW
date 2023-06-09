#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} F0404545
Gerenciamento de Movimenta��o de Veiculo - Gera��o de Doc. Fiscal
@author Sergio Compain
@since 30/10/19
@project	0000032563
@history 	30/09/2019, Sergio Compain, Desenvolvimento inicial (MIT044 - P04045 - IT05,CST07,CST10 e CST11 - Fluxo de Pesagem)
/*/

User Function F0404545()

    Local aAreaAtu := getArea()
    Local cFrango  := IIF(FindFunction("U_fOpMovim"),U_fOpMovim("FRANGO"), 	SuperGetMV("FS_C040452",, "") )
    Local cLorenz  := IIF(FindFunction("U_fOpMovim"),U_fOpMovim("LORENZ"), 	SuperGetMV("FS_C040457",, "") )
    Local cLenha   := IIF(FindFunction("U_fOpMovim"),U_fOpMovim("LENHA"),	SuperGetMV("FS_C040458",, "") )
    Local nPerPrd  := 0

	If !MsgYesNo("Deseja realmente gerar o doc. fiscal?", "Gera��o de Doc. Fiscal")
        Return()
	Endif

    If PC2->PC2_STATUS == "E"
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Movimenta��o j� Cancelada" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimenta��o"})
        Return()
    EndIf

    If PC2->PC2_STATUS == "C"
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Doc. Fiscal j� Concluido" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimenta��o"})
        Return()
    EndIf

    If PC2->PC2_STATUS == "A"
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Movimenta��o em aberto" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimenta��o"})
        Return()
    EndIf

	If PC2->PC2_STATUS == "P"
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Aguardando primeira pesagem" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimenta��o"})
        Return()
    EndIf

	If PC2->PC2_STATUS == "S"
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Aguardando segunda pesagem" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimenta��o"})
        Return()
    EndIf

    If PC2->PC2_SENTID == "S"
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Tipo de Movimenta��o n�o permite gerar Doc. Fiscal de Entrada" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o tipo da movimenta��o"})
        Return()
    EndIf

    If PC2->PC2_OPERA <> cFrango .and. PC2->PC2_OPERA <> cLorenz .and. PC2->PC2_OPERA <> cLenha
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Tipo de Movimenta��o n�o permite gerar Doc. Fiscal de Entrada" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Somente os Tipos os tipo Frango,Lorenz e Lenha"})
        Return()
    EndIf

	PAE->(DBSetOrder(1)) 
	If !PAE->(DBSeek(FwXFilial("PAE")+PC2->PC2_CTRLE))
        Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Movimenta��o sem Itens para gerar Doc. Fiscal de Entrada" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Inclua Itens para a Movimenta��o"})
        RestArea(aAreaAtu)
        Return()
    EndIf

    If PC2->PC2_OPERA == cLorenz
		nPerPrd := 0
        dbSelectArea("PAE")
		PAE->(dbsetOrder(1))
		If PAE->(dbSeek(xFilial("PAE")+PC2->PC2_CTRLE))
			While PAE->(!eof() .and. PAE->PAE_FILIAL == xFilial("PAE") .AND. PAE->PAE_CTRLE == PC2->PC2_CTRLE)
                nPerPrd += PAE->PAE_PERPRD
            	PAE->(dbSkip())
			End
		EndIf
        If nPerPrd <> 100
            Help(NIL, NIL, " Gera��o de Doc. Fiscal", NIL, "Movimenta��o Lorenz a % do Produtor n�o atingiu o 100%" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique os Itens da Movimenta��o"})
            RestArea(aAreaAtu)
            Return()
        EndIf
    EndIf

     //P04052 - Automatiza��o da gera��o das NFs do frango vivo para fornecedor fisico
    If PC2->PC2_OPERA == cFrango .and. PC2->PC2_PESO1 <> 0 .AND. PC2->PC2_PESO2 <> 0 .AND. PC2->PC2_PESLIQ <> 0 .AND. PC2->PC2_NFP == "S"
		U_F0405230(PC2->PC2_CTRLE)
	Else
		FwMsgRun(,{|| U_F0404550(PC2->PC2_CTRLE)},"Gerar Doc.Fiscal","P04045")
    EndIf

    RestArea(aAreaAtu)

Return()
