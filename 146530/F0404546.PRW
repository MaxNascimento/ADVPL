#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} F0404546
Gerenciamento de Movimentação de Veiculo - Reenvio Pesagem
@author Sergio Compain
@since 30/10/19
@project	0000032563
@history 	30/09/2019, Sergio Compain, Desenvolvimento inicial (MIT044 - P04045 - IT05,CST07,CST10 e CST11 - Fluxo de Pesagem)
/*/

User Function F0404546()

	Local cRegID   := AvKey(Alltrim(SuperGetMv("MV_CPLREG",,"")),"DK0_REGID")

	If !MsgYesNo("Deseja realmente reenviar a pesagem?", "Reenvio Pesagem")
        Return()
	Endif

	If PC2->PC2_STATUS == "A"
        Help(NIL, NIL, " Reenvio Pesagem", NIL, "Movimentação em aberto" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimentação"})
        Return()
    EndIf

	If PC2->PC2_STATUS == "P"
        Help(NIL, NIL, " Reenvio Pesagem", NIL, "Aguardando primeira pesagem" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimentação"})
        Return()
    EndIf

	If PC2->PC2_STATUS == "S"
        Help(NIL, NIL, " Reenvio Pesagem", NIL, "Aguardando segunda pesagem" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimentação"})
        Return()
    EndIf

    If PC2->PC2_STATUS == "E"
        Help(NIL, NIL, " Reenvio Pesagem", NIL, "Movimentação já Cancelada" , 2, 0, NIL, NIL, NIL, NIL, NIL,{"Verifique o Status da movimentação"})
        Return()
    EndIf

	If !Empty(PC2->PC2_VIAGEM)
		DK0->(dbsetOrder(1))
		If DK0->(dbSeek(xFilial("DK0")+cRegID+PC2->PC2_VIAGEM))
			If DK0->DK0_SITINT <> "2"
				Help(,,"[F0404540D] Erro na Inclusão da viagem.",,"A viagem " + PC2->PC2_VIAGEM + " não está com status de liberada!",;
						1, 0,,,,,,{"Selecione uma viagem liberada"})
			
				Return()
			Endif
		Endif
	Endif
	
	FwMsgRun(,{|| U_F0202201()},"Reenvio Pesagem","P04045")

Return()
