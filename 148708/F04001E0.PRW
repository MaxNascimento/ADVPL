#Include "Totvs.ch"

/*/{Protheus.doc} F04001E0

Gerar carga

@type function
@version  
@author fabio.cazarini
@since 15/04/2021
@return return_type, return_description
/*/
User Function F04001E0()
    Local aArea     	:= GetArea()
    Local aAreaDK0      := DK0->( GetArea() ) 
	Local cViagem       := PDB->PDB_VIAGID
    Local cRegId        := ""
    Local cCarga        := ""
    Local lContinua     := .F.
	
    Private cOperaGFE   := ""
    Private cClassGFE   := ""

	If PDB->PDB_STATUS $ "1" // 1=Wizard em andamento;2=Wizard concluído;3=Manutenção da viagem concluída;4=Carga gerada;5=Carga faturada
		MsgInfo("Somente é possível indicar a operação e classificação do frete com o wizard concluído e sem carga gerada!","F04001AA")
	Else
        cRegId := SuperGetMV("MV_CPLREG", .F., "")
        DK0->( DbSetOrder(1) ) // DK0_FILIAL+DK0_REGID+DK0_VIAGID
        If DK0->( DbSeek( xFilial("DK0") + Padr(cRegId, TamSX3("DK0_REGID")[1]) + cViagem ) )
            cCarga := DK0->DK0_CARGA
            If !Empty(cCarga)
                // Atualiza a carga da viagem em todos os registros de controle (tabela PDB) com a mesma viagem
                AtuaCarga(DK0->DK0_VIAGID, DK0->DK0_CARGA, "01")

                lContinua := MsgYesNo("A Viagem [" + cViagem + "] está vinculada a carga [" + DK0->DK0_CARGA  + "]." + CRLF + CRLF +;
                                         "Deseja continuar e informar o(s) lacre(s) da carga?")
            Else
                Begin Transaction
                    FWMsgRun(, {|| lContinua := U_F04001E1()}, "Montagem de Carga","Efetuando Montagem da Carga...")
                End Transaction
            EndIf

            If lContinua
                U_F04001F0() // Lacre de Carga
            Endif
        Else
            MsgAlert("O registro posicionado não possui viagem")
        EndIf
	Endif

    RestArea(aAreaDK0)
    RestArea(aArea)

Return


/*/{Protheus.doc} F04001E1

Geração de carga simulando a rotina GeraCarga do fonte OMSXCPL7.PRW.

Obs.1: DK0 deve estar posicionada.
Obs.2: Deve estar dentro de uma transação.

@type function
@version  
@author fabio.cazarini
@since 15/04/2021
@return return_type, return_description
/*/
User Function F04001E1()

    Local aArea     := {}
    Local aErros    := {}
    Local aMsg      := {}
    Local cErro     := ""
    Local nErro     := 0
    Local lRetorno  := .T.
    Local lContinua := .F.

    aArea := {GetArea(), DAI->(GetArea()), DK0->(GetArea()),PDB->(GetArea())}

	// Chama função padrão responsável por chamar a função "GERACARGA"
	// LOG de erro será apresentado pela rotina padrão após o processamento da carga
	//lRetorno := OMSXCPL7G()
	
    //&("StaticCall(OMSXCPL7, OmsGerCarg, aErros)") //Gera carga através da rotina do CPL

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
        lRetorno := .T.
    EndIf
	
	If lRetorno
        // Atualiza a carga da viagem em todos os registros de controle (tabela PDB) com a mesma viagem
        AtuaCarga(DK0->DK0_VIAGID, DK0->DK0_CARGA, "01")

        If MsgYesNo("Carga(s) ["+DK0->DK0_CARGA+"] gerada(s) com sucesso!" + CRLF + CRLF + "Deseja continuar e informar os lacres de carga?")
            lContinua := .T.
        Endif
    Else
        If InTransact()
            DisarmTransaction()
        EndIf
        cErro := "Nenhum registro válido selecionado para a geração de carga!"
        MsgAlert(cErro, "Geração de Carga")
    EndIf
	
    AEval(aArea, {|area| RestArea(area)})

    FwFreeArray(aMsg)
    FwFreeArray(aErros)

Return lContinua


/*/{Protheus.doc} AtuaCarga

Atualiza a carga da viagem em todos os registros de controle (tabela PDB) com a mesma viagem

@type function
@version  
@author fabio.cazarini
@since 03/05/2021
@param cViagem, character, param_description
@param cCarga, character, param_description
@param cSeqCarga, character, param_description
@return return_type, return_description
/*/
Static Function AtuaCarga(cViagem, cCarga, cSeqCarga)
    Local aAreaPDB := PDB->(GetArea())

    PDB->( DbSetOrder(2) ) // PDB_FILIAL+ PDB_VIAGID
    If PDB->( DbSeek( xFilial("PDB") + cViagem ) )
        Do While PDB->( !Eof() ) .and. PDB->PDB_FILIAL = xFilial("PDB") .and. PDB->PDB_VIAGID == cViagem
            If PDB->PDB_STATUS <> "4" .or. PDB->PDB_CARGA <> cCarga .or. PDB->PDB_SEQCAR <> cSeqCarga
                RecLock("PDB", .F.)
                    PDB->PDB_STATUS := "4"          // 1=Wizard em andamento;2=Wizard concluído;3=Manutenção da viagem concluída;4=Carga gerada;5=Carga faturada
                    PDB->PDB_CARGA  := cCarga       
                    PDB->PDB_SEQCAR := cSeqCarga    
                PDB->( MsUnLock() )
            Endif

            PDB->( DbSkip() )
        Enddo
    Endif

    RestArea(aAreaPDB)

Return 
