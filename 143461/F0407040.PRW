#include 'Totvs.ch'

/*/{Protheus.doc} F0407040
Executado do ponto de entrada PE01NFESEFAZ - Adiciona mensagem fiscal
@ Autor - Alexandre Caetano - [ACSJ]
@ Data  - 08/07/2020 
/*/
User Function F0407040( aDadosNF, aNota )
	Local aAreaSC5		:= GetArea("SC5") 
    Local cFSC040702    := SuperGetMV("FS_C040702", .T., "")
    Local cTxt          := Alltrim( aDadosNF[3] )   //Mensagem Fiscal [cMensCli]
	Local cTipo 		:= aNota[04] // 0=Entrada;1=Saída 

    SC5->( dbSetOrder(1) )  //C5_FILIAL+C5_NUM
	If cTipo == "1" .and. SC5->( dbSeek( xFilial("SC5") + SD2->D2_PEDIDO ) )
		If !( SC5->C5_TIPO $ "D" )//Removido conforme Mauricio GT falou If !( SC5->C5_TIPO $ "DB" )
			If SC5->C5_XICMFRE > 0
				cTxt        += iif( Empty(cTxt) ,"" ," " ) + Alltrim( cFSC040702 )
				cTxt        += " VLR FRETE "      + Alltrim(Transform(SC5->C5_XVALFRE ,avSx3("C5_XVALFRE"   ,6) ))
				cTxt        += " VLR ICMS FRETE " + Alltrim(Transform(SC5->C5_XICMFRE ,avSx3("C5_XICMFRE"   ,6) ))
				aDadosNF[3] := FwNoAccent(cTxt)
			Endif
		Endif
    Endif

    RestArea(aAreaSC5)

Return(aDadosNF)
