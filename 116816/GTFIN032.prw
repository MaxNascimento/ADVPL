#Include 'Totvs.ch'
#Include 'TopConn.ch'

User Function GTFIN032()
local nRet 
      
IF (FunName() == ("FINA050"))   
    IF LEFT(M->E2_NATUREZ,1)=="3" .AND. Empty(M->E2_CCUSTO)
        nRet:=.F.  
        MsgAlert("Para natureza do grupo 3..., é necessário incluir centro de custo", "Alerta")
    ELSE
        nRet := .T.
    ENDIF
ELSE  
    nRet := .T.
ENDIF

Return(nRet)
