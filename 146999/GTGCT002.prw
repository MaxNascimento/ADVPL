#INCLUDE "Protheus.ch"
#INCLUDE "FWMVCDEF.CH"
 
/*{Protheus.doc} CNTA121()
     
*/
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �GTGCT002�Autor  �Reginaldo G Ribeiro � Data �  23/09/21   ���
�������������������������������������������������������������������������͹��
���Desc.     � Possibilitar ao desenvolvedor realizar a mesma opera��o     ��
���          �anteriormente feita no ponto de entrada CN120ENVL            ��
�������������������������������������������������������������������������͹��
���Uso       �                               ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
User Function GTGCT002(PARAMIXB)
    Local aParam := PARAMIXB
    Local xRet := .T.
    Local oModel := ''
    Local cIdPonto := ''
    Local cIdModel := ''
    Local _oModeL 		
    Local _oModelCXN	
 
    If aParam <> NIL
        oModel  := aParam[1]
        cIdPonto:= aParam[2]
        cIdModel:= aParam[3]
         
        /*O evento de id <MODELVLDACTIVE> ser� sempre chamado ao iniciar uma opera��o com o modelo de dados via m�todo Activate do MPFormModel,
        ent�o para nos certificarmos que a valida��o s� ser� executada no encerramento tal qual o p.e CN120ENVL, � necess�rio verificar se a chamada est� sendo realizada
        atrav�s da fun��o CN121MedEnc, pra isso utilizamos a fun��o FwIsInCallStack
         */
        If cIdPonto == "FORMLINEPOS".And. FwIsInCallStack("CN121MedEnc")//
            /*Como o modelo ainda n�o foi ativado, devemos utilizar as tabelas p/ valida��o, a �nica informa��o que constara em oModel
            ser� a opera��o(obtida pelo m�todo GetOperation), que nesse exemplo sempre ser� MODEL_OPERATION_UPDATE.                
            */
            dbSelectArea("CNA")
            dbSetOrder(1)
            If CNA->(dbSeek(xFilial("CNA")+CN9->CN9_NUMERO))
                If fSldSdt()>0
                    _oModeL 	:= FwModelActive()
                    _oModelCXN	:= _oModel:GetModel("CXNDETAIL")
                    if _oModelCXN:GetValue("CXN_VLRADI")==0
                        //Help("",1,"Cn121TudOk",,"Nao foi possivel realizar essa operacao, Contrato com saldo de adiantamento.",1,1)
                        MsgStop("Nao foi possivel realizar essa operacao, Contrato com saldo de adiantamento.","Aten��o")
                        xRet := .F.
                    Endif    
                EndIf
                IF fSldZa2()>0 .and. xRet
                    //Help("",1,"Cn121TudOk",,"Existe Titulo de Provis�o para este contrato.",1,1)
                    MsgAlert("Existe Titulo de Provis�o para este contrato.","Alerta")
                    //xRet := .F. 
                ENDIF
            EndIf    
        EndIf
        /*
        If cIdPonto == "MODELCOMMITNTTS" .and. FwIsInCallStack("CN121MedEnc")
            DbSelectArea("CNX")
			CNX->(DbsetOrder(1))
			If CNX->(MsSeek(xFilial("CNX")+CZY->CZY_CONTRA+CZY->CZY_NUMERO))
                dbSelectArea("SE2")
                dbSetOrder(6)  
                If SE2->(dbseek(xFilial("SE2")+CNX->CNX_FORNEC+CNX->CNX_LJFORN+CNX->CNX_PREFIX+CNX->CNX_NUMTIT))
                    If FIE->(MsSeek(xFilial("FIE")+"P"+SE2->(E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SC7->C7_NUM))
                        RecLock( "FIE", .F. )
                    Else
                        RecLock( "FIE", .T. )
                    Endif
                    FIE->FIE_FILIAL	:= xFilial( "FIE" )
                    FIE->FIE_CART	:= "P"
                    FIE->FIE_PEDIDO	:= SC7->C7_NUM
                    FIE->FIE_PREFIX	:= SE2->E2_PREFIXO
                    FIE->FIE_NUM	:= SE2->E2_NUM
                    FIE->FIE_PARCEL	:= SE2->E2_PARCELA
                    FIE->FIE_TIPO	:= SE2->E2_TIPO
                    FIE->FIE_FORNEC	:= SE2->E2_FORNECE
                    FIE->FIE_LOJA	:= SE2->E2_LOJA
                    FIE->FIE_VALOR	:= SE2->E2_VALOR                        
                    FIE->FIE_SALDO	:= SE2->E2_VALOR  
                    FIE->FIE_FILORI := xFilial( "FIE" )
                    
                    FIE->( MsUnLock() )
                EndIf
            Endif
        EndIf
        */
    EndIf
Return xRet

Static function fSldSdt
Local cQryadt:= ""
local nRet:= 0
    cQryadt+= " SELECT SUM(CNX_SALDO) SALDO FROM "+RetSqlName("CNX")+" CNX"
    cQryadt+= " WHERE CNX.D_E_L_E_T_<>'*' AND CNX.CNX_CONTRA='"+CNA->CNA_CONTRA+"'"
    cQryadt+= " AND CNX_FILIAL='"+CNA->CNA_FILIAL+"' AND CNX_FORNEC='"+CNA->CNA_FORNEC+"' AND CNX_LJFORN='"+CNA->CNA_LJFORN+"'"
    cQryadt:= ChangeQuery(cQryadt)
    If SELECT("TADT")>0
        dbSelectArea("TADT")
        TADT->(dbCloseArea())
    EndIf
    dbUseArea(.T., "TOPCONN", TCGENQRY(,,cQryadt), 'TADT', .F., .T.)

    If TADT->(!Eof())
        nRet:= TADT->SALDO
    EndIf
Return nRet


Static function fSldZa2
Local cQryZA2:= ""
local nRet:= 0
    cQryZA2+= " SELECT SUM(ZA2_VALOR) SALDO FROM "+RetSqlName("ZA2")+ " ZA2" 
    cQryZA2+= " WHERE ZA2_CONTR='"+CND_CONTRA+"' AND ZA2.D_E_L_E_T_<>'*'
    cQryZA2:= ChangeQuery(cQryZA2)
    If SELECT("TZA2")>0
        dbSelectArea("TZA2")
        TZA2->(dbCloseArea())
    EndIf
    dbUseArea(.T., "TOPCONN", TCGENQRY(,,cQryZA2), 'TZA2', .F., .T.)

    If TZA2->(!Eof())
        nRet:= TZA2->SALDO
    EndIf

Return nRet
