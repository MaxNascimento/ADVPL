#INCLUDE "Protheus.ch"
#INCLUDE "FWMVCDEF.CH"
 
/*{Protheus.doc} CNTA121()
     
*/
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณGTGCT002บAutor  ณReginaldo G Ribeiro บ Data ณ  23/09/21   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Possibilitar ao desenvolvedor realizar a mesma opera็ใo     ฑฑ
ฑฑบ          ณanteriormente feita no ponto de entrada CN120ENVL            ฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ                               บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
         
        /*O evento de id <MODELVLDACTIVE> serแ sempre chamado ao iniciar uma opera็ใo com o modelo de dados via m้todo Activate do MPFormModel,
        entใo para nos certificarmos que a valida็ใo s๓ serแ executada no encerramento tal qual o p.e CN120ENVL, ้ necessแrio verificar se a chamada estแ sendo realizada
        atrav้s da fun็ใo CN121MedEnc, pra isso utilizamos a fun็ใo FwIsInCallStack
         */
        If cIdPonto == "FORMLINEPOS".And. FwIsInCallStack("CN121MedEnc")//
            /*Como o modelo ainda nใo foi ativado, devemos utilizar as tabelas p/ valida็ใo, a ๚nica informa็ใo que constara em oModel
            serแ a opera็ใo(obtida pelo m้todo GetOperation), que nesse exemplo sempre serแ MODEL_OPERATION_UPDATE.                
            */
            dbSelectArea("CNA")
            dbSetOrder(1)
            If CNA->(dbSeek(xFilial("CNA")+CN9->CN9_NUMERO))
                If fSldSdt()>0
                    _oModeL 	:= FwModelActive()
                    _oModelCXN	:= _oModel:GetModel("CXNDETAIL")
                    if _oModelCXN:GetValue("CXN_VLRADI")==0
                        //Help("",1,"Cn121TudOk",,"Nao foi possivel realizar essa operacao, Contrato com saldo de adiantamento.",1,1)
                        MsgStop("Nao foi possivel realizar essa operacao, Contrato com saldo de adiantamento.","Aten็ใo")
                        xRet := .F.
                    Endif    
                EndIf
                IF fSldZa2()>0 .and. xRet
                    //Help("",1,"Cn121TudOk",,"Existe Titulo de Provisใo para este contrato.",1,1)
                    MsgAlert("Existe Titulo de Provisใo para este contrato.","Alerta")
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
