#Include 'Totvs.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} GTFAT031
// Validação para preencher campo transportador ao incluir pedido de venda
@type       User Function
@version    1.0
@author     Max Nascimento
@since      04/11/2022
/*/

User Function GTFAT031()
    Local cTpCarga      := M->C5_TPCARGA
	Local cTpFrete      := M->C5_TPFRETE
    Local cTransp       := M->C5_TRANSP
    Local lRet := .F.

    //Chamada da função de controle de versao
	If FindFunction("VERSAOGT")
		SetKey(K_CTRL_F12, {||VERSAOGT()})
	Else
		SetKey(K_CTRL_F12, Nil)
	EndIf

	If Alltrim(cTpFrete) == ""
    	lRet := .F.
    	Help(,,"GTFAT031",, "O campo Tipo Frete esta em branco.", 1, 0,,,,,,{"Selecione o tipo de frete"})
	Else
		If Alltrim(cTpCarga) == ""
			lRet := .F.
			Help(,,"GTFAT031",, "O campo Carga esta em branco.", 1, 0,,,,,,{"Selecione se utiliza formação de carga"})
		Else
			//Valida se o frete é CIF, utiliza carga e o campo transportador está vazio
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
		Endif
	Endif

	
Return lRet


Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)
	
	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL
	
	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10) 
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "001.0   MAX MIGUEL         130224    04/11/22 " + CHR(10) //Validação do campo transp
	@ 10,70 SAY oSay PROMPT "GTFAT031" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
		
	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
