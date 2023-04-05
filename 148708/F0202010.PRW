#Include "Protheus.ch"

/*/{Protheus.doc} F0202010
Geração de carga simulando a rotina GeraCarga do fonte OMSXCPL7.PRW.

Obs.1: DK0 deve estar posicionada.
Obs.2: Deve estar dentro de uma transação.

@author     Rafael Riego
@since      16/09/2019
@return     Nil
/*/ 
User Function F0202010()

    Local aArea     := {}
    Local aErros    := {}
    Local aMsg      := {}
    Local aRetorno  := {.T., ""}
    Local cErro     := ""
    Local nErro     := 0
    Local lRetorno  := .T.

    Private cOperaGFE   := ""
    Private cClassGFE   := ""

    aArea := {GetArea(), DAI->(GetArea()), DK0->(GetArea())}

    // Chama função padrão responsável por chamar a função "GERACARGA"
	// LOG de erro será apresentado pela rotina padrão após o processamento da carga
	
    //&("StaticCall(OMSXCPL7, GeraCarga, aErros)")

    OmsGerCarg(@aErros)

    If !(Empty(aErros))
        If InTransact()
            DisarmTransaction()
        EndIf
        cErro := "Resumo das divergências ao gerar a carga para as viagens selecionadas:"
        Aadd(aMsg, cErro)
        cErro += CRLF   
        For nErro := 1 To Len(aErros)
            AAdd(aMsg, aErros[nErro])
            cErro += aErros[nErro] + CRLF
        Next nErro
        OMSShowWng(aMsg)
        aRetorno := {.F., cErro}
        lRetorno := .F.
    EndIf 
	
	If lRetorno
        OMSMessage("Carga(s) ["+DK0->DK0_CARGA+"] gerada(s) com sucesso!")

		RecLock("PC2", .F. )
			PC2->PC2_CARGA := DK0->DK0_CARGA
		PC2->( MsUnLock() )
		
       //Gravação complementar das placas na carga gerada
        IF !Empty(DK0->DK0_CARGA)
			U_F0202014(DK0->DK0_FILIAL, DK0->DK0_CARGA)
		EndIF
    Else
        If InTransact()
            DisarmTransaction()
        EndIf
        cErro := "Nenhum registro válido selecionado para a geração de carga!"
        MsgAlert(cErro, "Geração de Carga")
        aRetorno := {.F., cErro}
    EndIf
	
    AEval(aArea, {|area| RestArea(area)})

    FwFreeArray(aMsg)
    FwFreeArray(aErros)

Return aRetorno
