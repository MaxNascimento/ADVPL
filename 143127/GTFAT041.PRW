#Include 'Totvs.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} GTFAT041
// Validação para preencher os campos quando for item de venda no cadastro de produtos
@type       User Function
@version    1.0
@author     Max Nascimento
@since      01/02/2023
/*/

User Function GTFAT041()
    Local nPeso     := M->B1_PESO
	Local nPesbru   := M->B1_PESBRU
    Local nConv     := M->B1_CONV
    Local cVenda    := M->B1_XVENDA
    Local cSegUM    := M->B1_SEGUM

    Local lRet := .F.

    //Chamada da função de controle de versao
	If FindFunction("VERSAOGT")
		SetKey(K_CTRL_F12, {||VERSAOGT()})
	Else
		SetKey(K_CTRL_F12, Nil)
	EndIf

    //Valida se o item cadastrado é um produto de venda
    If cVenda == "S" 
        If nPeso == 0
            lRet := .F.
            Help(,,"GTFAT041",, "O campo Peso Liquido não foi preenchido.", 1, 0,,,,,,{"Informe o valor do campo"})
        Else
            If nPesbru == 0
                lRet := .F.
                Help(,,"GTFAT041",, "O campo Peso Bruto não foi preenchido.", 1, 0,,,,,,{"Informe o valor do campo"})
            Else
                If nConv == 0
                    lRet := .F.
                    Help(,,"GTFAT041",, "O campo Fator Conv. não foi preenchido.", 1, 0,,,,,,{"Informe o valor do campo"})
                Else
                    If Empty(cSegUM)
                        lRet := .F.
                        Help(,,"GTFAT041",, "O campo Seg.Un.Medi. não foi preenchido.", 1, 0,,,,,,{"Preencha o campo vazio"})
                    Else
                        lRet := .T.
                    Endif
                Endif
            Endif
        Endif

    Else
        lRet := .T.  
    Endif    
    
Return lRet


Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)
	
	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL
	
	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10) 
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "001.0   MAX MIGUEL         143127    01/02/23" + CHR(10) //Validação do campo Peso
	@ 10,70 SAY oSay PROMPT "GTFAT031" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
		
	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
