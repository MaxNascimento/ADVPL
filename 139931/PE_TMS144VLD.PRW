#Include "Totvs.ch"

/*/{Protheus.doc} TMS144VLD
//Ponto de Entrada, localizado no TMSA144 (Viagem Modelo 2), 
é utilizado na validação da viagem(Coleta, Rodoviária e Entrega) 
no momento da confirmação.
@author Tiago Dantas da Cruz
@since 29/06/2020
@version 1.0
@return Logico
@type function
/*/
User Function TMS144VLD() 

    Local lRet      := .T.
    Local nOpcx     := PARAMIXB[1]
    Local dDtEnc    := DTQ->DTQ_DATENC
    Local cStatus   := DTQ->DTQ_STATUS
    Local cViagem   := DTQ->DTQ_VIAGEM
    Local cFilViag  := DTQ->DTQ_FILORI

    If nOpcx == 4 //Exclusao      
		lRet:= U_F040652D(dDtEnc,cStatus,cViagem,cFilViag,nOpcx)            
    EndIf

Return lRet
