#Include 'Totvs.ch'
#Include 'TopConn.ch'

/*/
    Valida��o para preencher campo transportador
    @author Max Nascimento
    @since 04/11/2022
/*/

User Function GTFAT031()
    Local cTpCarga      := M->C5_TPCARGA
	Local cTpFrete      := M->C5_TPFRETE
    Local cTransp       := M->C5_TRANSP
    Local lRet := .F.

    //Chamada da fun��o de controle de versao
	If FindFunction("VERSAOGT")
		SetKey(K_CTRL_F12, {||VERSAOGT()})
	Else
		SetKey(K_CTRL_F12, Nil)
	EndIf

    //Valida se o frete � CIF, utiliza carga e o campo transportador est� vazio
    If cTpCarga == "2" .And. cTpFrete == "C"
        If Alltrim(cTransp) == ""
            lRet := .F.
              Help(,,"GTFAT031",, "O campo Transp. esta em branco.", 1, 0,,,,,,{"Preencha o campo vazio"})
        Else
            lRet := .T.
        Endif
    Else
        lRet := .T.  
    Endif    
    
Return lRet


Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)
	
	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Vers�o" PIXEL
	
	cTexto := "VERS�O  AUTOR              CHAMADO    DATA   " + CHR(10) 
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "001.0   MAX MIGUEL         130224    04/11/22 " + CHR(10) //Valida��o do campo transp
	@ 10,70 SAY oSay PROMPT "GTFAT031" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
		
	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
