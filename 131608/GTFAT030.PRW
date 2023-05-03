#INCLUDE "Totvs.ch"

//==============================================================================================
/*
{Protheus.doc} GTFAT030()
Ponto de entrada utilizado no momento da Classificação da Nota de Entrada
@Author     Maycon Motta da Silva
@Since      11/11/2022
@Version    1.0
@Return     TRUE OR FALSE
@Project    131605
@history    
*/
//==============================================================================================

User Function GTFAT030()

    Local lRet     := .T.
    Local aArea    := GetArea()
    local cGerar   := ""
    local cTes     := ""
    local nX       := 0

    If FindFunction("VERSAOGT")
        SetKey(K_CTRL_F12, {||VERSAOGT()})
    Else
        SetKey(K_CTRL_F12, Nil) 
    EndIf

    


    If FunName() == 'MATA103'
        For nX := 1 to len(Acols)
  
        SF4->(DbSetOrder(1))
        IF SF4->(DbSeek(xFilial("SF4")+Acols[nX][18])) 
            cGerar := SF4->F4_DUPLIC
            cTes   := SF4->F4_CODIGO
        ENDIF
    
        if cGerar  == 'S' .and. Alltrim(Acols[nX][43]) == ''
            lRet := .F.
            Help(,,"GTFAT030",, "O Tipo de Entrada "+ cTes +" informado utiliza Movimentação Financeira.", 1, 0,,,,,,{"Informe o Pedido de Compra vinculado."})
        ENDIF

        RestArea(aArea)

        next nX
    Endif

Return lRet

Static Function VersaoGT()
    Local cTexto := ""
    Local oDlg, oSay
    Local oFont:= TFont():New("Courier New",,-14,.T.)
    
    DEFINE MSDIALOG oDlg FROM 0,0 TO 400,400 TITLE "Controle de Versão" PIXEL
    
    cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10) 
    cTexto += "======  =================  =======  ======== " + CHR(10)
    cTexto += "001.1   MAX NASCIMENTO     131608   20/04/23 " + CHR(10) // Ajuste na rotina
    cTexto += "001.0   Maycon Motta       131608   24/11/22 " + CHR(10) // Criação do controle de versao
    @ 10,70 SAY oSay PROMPT "GTFAT030" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
    @ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
        
    ACTIVATE MSDIALOG oDlg CENTERED
Return .T.



