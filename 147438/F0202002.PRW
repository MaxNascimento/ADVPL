#Include "Protheus.ch"
#include "fwmvcdef.ch"
#Include "XMLXFun.ch"

#Define DEF_FILPED   1
#Define DEF_PEDIDO   2
#Define DEF_ITEMPE   3
#Define DEF_CARGA    4
#Define DEF_REGID    5
#Define DEF_VIAGID   6


/*/{Protheus.doc} F0202002
Rotina localizada no botao 'Enviar Carregamento eData' na tela de pesagem. 
vinculo entre os pedidos e carga.

@type       User Function
@author     Rafael Riego
@since      16/09/2019
@return     Nil
/*/
User Function F0202002()

    FWMsgRun(, {|| PedVCarga()}, "Pedido de Venda & Carga",;
            "Efetuando envio dos pedidos de venda e criando carga eData...")

Return Nil

//Chamada da função de controle de versao
	If FindFunction("VERSAOGT")
		SetKey(K_CTRL_F12, {||VERSAOGT()})
	Else
		SetKey(K_CTRL_F12, Nil)
	EndIf

/*{Protheus.doc} PedVCarga
Realiza o envio dos Pedidos de Venda e a geracao de carga no eData.

@type       Static Function
@author     Rafael Riego
@since      16/09/2019
@return     Nil
*/
Static Function PedVCarga()

    Local aArea         := {}
    Local aPedidos      := {}
    Local aResultado    := {}

    Local cMsgErro      := ""

    Local nPedido       := 0
    Local nPosPed       := 0
    Local nPedidos      := 0
	Local lEnvEdata		:= .F.

    aArea := {DK0->(GetArea()), DK1->(GetArea()), SC5->(GetArea()), PC2->(GetArea()), GetArea()}

    If DK0->DK0_XINTEG == "2" //Integrada
        Aviso("Atencao", "Viagem ja integrada com sistema eData.", {"Fechar"}, 1)
        Return Nil
    EndIf

	If DK0->DK0_SITINT <> "2"
		Aviso("Atencao", "A viagem " + DK0->DK0_VIAGID + " não está com status de liberada!", {"Fechar"}, 1)
        Return Nil
	Endif
	
    SC5->(DbSetOrder(1))
    DK1->(DbSetOrder(1))
    cSeek := FWxFilial("DK1") + DK0->DK0_REGID + DK0->DK0_VIAGID
    If DK1->(DbSeek(cSeek)) //Posiciona no 1o item da viagem

        While !DK1->(EoF()) .And. cSeek ==  (DK1->DK1_FILIAL+DK1->DK1_REGID+DK1->DK1_VIAGID)
            SC5->(DbSeek(DK1->DK1_FILPED+ DK1->DK1_PEDIDO)) 
			lEnvEdata := !(U_F0202001()) // Valida se envia ao eData - .T. = não envia ao eData, .F. = Envia ao eData (e não permite liberação manual do estoque)
            If !lEnvEdata
				// se não envia ao eData
                DK1->(DbSkip())
                Loop
            EndIf

            lAadd := .F.
            
            If Empty(aPedidos)
                AAdd(aPedidos, {{DK1->DK1_FILPED, DK1->DK1_PEDIDO, DK1->DK1_ITEMPE, DK0->DK0_CARGA, DK0->DK0_REGID, DK1->DK1_VIAGID}})
            Else
                nPedidos := Len(aPedidos)
                For nPedido := 1 To nPedidos
                    nPosPed := AScan(aPedidos[nPedido], {|x| x[DEF_FILPED] + x[DEF_PEDIDO] == DK1->DK1_FILPED + DK1->DK1_PEDIDO})
                    If nPosPed > 0
                        AAdd(aPedidos[nPedido], {DK1->DK1_FILPED, DK1->DK1_PEDIDO, DK1->DK1_ITEMPE, DK0->DK0_CARGA,DK0->DK0_REGID,;
                            DK1->DK1_VIAGID})
                        lAadd := .F. // estava gerando a array em duplicidade                                                    
                    Else
                        lAadd := .T.                        
                    EndIf
                Next nPedido
                IF lAadd
                    AAdd(aPedidos, {{DK1->DK1_FILPED, DK1->DK1_PEDIDO, DK1->DK1_ITEMPE, DK0->DK0_CARGA, DK0->DK0_REGID, DK1->DK1_VIAGID}})
                Endif
            EndIf
            DK1->(DbSkip())
        End
     
        //Os dois lacos abaixo sao necessarios para efetuar 1o a validacao de todos os pedidos, acumulando as msgs de erro e
        //para que seja possivel enviar 1 a 1 apos a validacao geral
        nPedidos := Len(aPedidos)

		If nPedidos == 0
			cMsgErro += "Erro(s): Não há nenhum pedido para enviar ao eData" + CRLF + CRLF
		Else
			For nPedido := 1 To nPedidos
				aResultado := VerifSC9(aPedidos[nPedido]) // {Resultado .T. ou .F., Mensagem de Erro caso .F.}

				If !(aResultado[1])
					cMsgErro += "[Filial: " + AllTrim(aPedidos[nPedido][1][DEF_FILPED]) + " Pedido: " +;
						AllTrim(aPedidos[nPedido][1][DEF_PEDIDO]) + "]" + CRLF
					cMsgErro += "Erro(s):" + aResultado[2] + CRLF + CRLF
				EndIf
				aResultado := {}
			Next nPedido
		Endif
		
        If Empty(cMsgErro)
            For nPedido := 1 To Len(aPedidos)
                aResultado := EnvPdVenda(aPedidos[nPedido])
                If !(aResultado[1])
                    cMsgErro += "[Filial: " + AllTrim(aPedidos[nPedido][1][DEF_FILPED]) + " Pedido: " +;
                        AllTrim(aPedidos[nPedido][1][DEF_PEDIDO]) + "]" + CRLF
                    cMsgErro += "Erro:" + aResultado[2] + CRLF + CRLF
                    If 'ASO-001' $ UPPER(aResultado[2]) // 'ASO-001 - Parâmetro Código Externo do Pedido de Venda (SalesOrderNo) informado já existe'
                        aResultado := EnvCargaPV(aPedidos)
                        If !(aResultado[1])
                            cMsgErro := aResultado[2]
                        Else
                            GrvNumLoad(DK0->(Recno()), aResultado[3])
                        EndIf
                    EndIf    
                Else
                    GrvNumPV(aPedidos[nPedido], aResultado[3])
                EndIf
                aResultado := {}
            Next nPedido

            //Envio das cargas
            If Empty(cMsgErro)
                aResultado := EnvCargaPV(aPedidos)
                If !(aResultado[1])
                    cMsgErro := aResultado[2]
                Else
                    GrvNumLoad(DK0->(Recno()), aResultado[3])
                EndIf
            EndIf
        EndIf

        If !(Empty(cMsgErro))
            Aviso("Envio de Carga", cMsgErro, {"Fechar"}, 3)
        Else
            RecLock("DK0", .F.)
            DK0->DK0_XINTEG := "2" //Integrado
            DK0->(MsUnlock())
            Aviso("Envio de Pedidos & Carga", "Envio de Pedidos de Venda e Geracao de carga efetuados com sucesso.", {"Fechar"}, 2)
        EndIf
    Else
        Aviso("Envio de Pedidos & Carga", "Nenhum item foi encontrado para a viagem selecionada", {"Fechar"}, 2)
    EndIf

    FwFreeArray(aPedidos)
    AEval(aArea, {|area| RestArea(area)})

Return Nil

/*/{Protheus.doc} GrvNumPV
Verifica liberacao de credito do pedido de venda.

@type       Static Function
@author     Rafael Riego
@since      16/09/2019
@param      aPedido, array, array contendo todos os itens do pedido de venda
@param      nPVeData, numeric, 
@return     Nil
/*/
Static Function GrvNumPV(aPedido, nPVeData)

    Local nItem     := 0
    Local nQtdItens := 0

    //Default aPedido := {}

    aArea := {DK1->(GetArea()), GetArea()}

    nQtdItens := Len(aPedido)

    //DK1_FILIAL+DK1_FILPED+DK1_PEDIDO+DK1_ITEMPE
    DK1->(DbSetOrder(2))
    For nItem := 1 To nQtdItens
        If DK1->(DbSeek(FwXFilial("DK1", aPedido[nItem][DEF_FILPED]) + aPedido[nItem][DEF_FILPED] +;
                aPedido[nItem][DEF_PEDIDO] + aPedido[nItem][DEF_ITEMPE]))
            Reclock("DK1", .F.)
            DK1->DK1_XEDATA := nPVeData
            DK1->(MsUnlock())
        EndIf
    Next nItem

    AEval(aArea, {|area| RestArea(area)})

Return Nil

/*/{Protheus.doc} GrvNumLoad
Grava numero da carga gerada no sistema eData.

@type       Static Function
@author     Rafael Riego
@since      16/09/2019
@param      nRecnoDK0, numeric, numero do Recno DK0
@param      nNumCarga, numeric, numero da carga gerado no eData
@return     Nil
/*/
Static Function GrvNumLoad(nRecnoDK0, nNumCarga)

    Default nRecnoDK0   := 0

    aArea := {DK0->(GetArea()), GetArea()}

    If nRecnoDK0 != 0
        DK0->(DbGoTo(nRecnoDK0))
    EndIf

    Reclock("DK0", .F.)
    DK0->DK0_XEDCAR := nNumCarga
    DK0->(MsUnlock())

    AEval(aArea, {|area| RestArea(area)})

Return Nil

/*/{Protheus.doc} VerifSC9
Verifica liberacao de credito do pedido de venda.

@type       Static Function
@author     Rafael Riego
@since      16/09/2019
@param      aPedido, array, array contendo todos os itens do pedido de venda
@return     Nil
/*/
Static Function VerifSC9(aPedido)

    Local aArea     := {}

    Local cAliasQry := ""
    Local cBlqCred  := ""
    Local cMotivBlq := ""
    Local cMsgErro  := ""
    Local cProduto  := ""
    Local cQuery    := ""

    Local lLiberado := .T.

    //Default aPedido := {}

    If Empty(aPedido)
        Return {.F., "Pedido de Venda sem itens."}
    EndIf

    aArea := {SC9->(GetArea()), GetArea()}
    //Na query e utilizado somente o 1o array pois a verificacao nao utiliza item
    cQuery := "SELECT SC9.R_E_C_N_O_ RECNOSC9"
    cQuery += "   FROM " + RetSqlName("SC9") + " SC9 "
    cQuery += " INNER JOIN " + RetSQLName("DK1") + " DK1 ON "
    cQuery += "     DK1.DK1_FILIAL = '" + FwXFilial("DK1", aPedido[1][DEF_FILPED]) + "' "
    cQuery += " AND DK1.DK1_FILPED = SC9.C9_FILIAL "
    cQuery += " AND DK1.DK1_PEDIDO = SC9.C9_PEDIDO "
    cQuery += " AND DK1.D_E_L_E_T_ = ' ' "
    cQuery += " WHERE SC9.C9_FILIAL = '" + FwXFilial("SC9", aPedido[1][DEF_FILPED]) + "' "
    cQuery += "   AND SC9.C9_PEDIDO = '" + aPedido[1][DEF_PEDIDO] + "' "
    cQuery += "   AND SC9.C9_CARGA  = '" + aPedido[1][DEF_CARGA] + "' "
    cQuery += "   AND SC9.D_E_L_E_T_ = ' ' "
    cQuery += "   AND DK1.DK1_REGID  = '" + aPedido[1][DEF_REGID] + "' "
    cQuery += "   AND DK1.DK1_VIAGID = '" + aPedido[1][DEF_VIAGID] + "' "

    cQuery := ChangeQuery(cQuery)

    cAliasQry := MPSysOpenQuery(cQuery)

    If (cAliasQry)->(!(EoF()))
        While (cAliasQry)->(!(EoF()))
            SC9->(DbGoTo((cAliasQry)->RECNOSC9))
            //Variavel criada apenas para testar todas as possibilidades
            cBlqCred := SC9->C9_BLCRED
            cProduto := AllTrim(SC9->C9_PRODUTO)
            If cBlqCred == '01'
                cMotivBlq := "Produto: " + cProduto + "/" + SC9->C9_ITEM + " - Bloqueado p/ credito"
            ElseIf cBlqCred == "02"
                cMotivBlq := "Produto: " + cProduto + "/" + SC9->C9_ITEM + " - MV_BLQCRED = .T."
            ElseIf cBlqCred == "04"
                cMotivBlq := "Produto: " + cProduto + "/" + SC9->C9_ITEM + " - Limite de Credito Vencido"
            ElseIf cBlqCred == "05"
                cMotivBlq := "Produto: " + cProduto + "/" + SC9->C9_ITEM + " - Bloqueio Credito por Estorno"
            ElseIf cBlqCred == "06"
                cMotivBlq := "Produto: " + cProduto + "/" + SC9->C9_ITEM + " - Bloqueio por risco"
            ElseIf cBlqCred == "09"
                cMotivBlq := "Produto: " + cProduto + "/" + SC9->C9_ITEM + " - Rejeitado"
            ElseIf cBlqCred == "10"
                cMotivBlq := "Produto: " + cProduto + "/" + SC9->C9_ITEM + " - Ja Faturado"
            EndIf
            //Acumulador de Mensagem por item
            If !(Empty(cMotivBlq))
                cMsgErro +=  CRLF + cMotivBlq
                cMotivBlq := ""
            EndIf
            (cAliasQry)->(DbSkip())
        End
    Else
        cMsgErro := "Nenhum Pedido de Venda foi encontrado com o status 'Liberado'."
    EndIf

    If !(Empty(cMsgErro))
        //Help(,, "Lib. Cred", "Lib. Cred", cMsgErro, 1, 1,,,,,, {""})
        lLiberado := .F.
    EndIf

    (cAliasQry)->(DbCloseArea())

    AEval(aArea, {|area| RestArea(area)})

Return {lLiberado, cMsgErro}

/*/{Protheus.doc} EnvPdVenda
Rotina localizada no botao 'Enviar Carregamento eData' na tela de pesagem.

@type       Static Function
@author     Rafael Riego
@since      16/09/2019
@param      aPedido, array, array contendo todos os itens do pedido de venda
@return     Nil
/*/
Static Function EnvPdVenda(aPedido, lFswTeste)

    Local aArea         := {}

    Local cAviso        := ""
    Local cErro         := ""
    Local cEstDesc      := ""
    Local cEstEDesc     := ""
    Local cMetodo       := ""
    Local cMsgErro      := ""
    Local cPaisDesc     := ""
    Local cPassword     := ""
    Local cSOAPRet      := ""
    Local cSOAPXML      := ""
    Local cTipoFrete    := ""
    Local cURL          := ""
    Local cUsuario      := ""
    Local lEnvSucess    := .T.
    Local nPedVeData    := 0
    Local oTWSDLMngr    := Nil
    Local oXML          := Nil
    Local nItem
    Local aSOAPRet      := ""
    Local nPosSOAPRet   := ""
    Local cErrorCode    := ""
	Local dEntrega		:= Ctod("//")
	Local aEnvPedido	:= {}
	Local aEnvAux		:= {}
    Local cFilPed       := ""
	Local aRet			:= {}
	
	Default lFswTeste	:= .F. // eh teste automatizado da FSW?

    aArea   := {SC5->(GetArea()), SC6->(GetArea()), SA1->(GetArea()), SYA->(GetArea()), SX5->(GetArea()), GetArea()}

    cMetodo := "PostAddSalesOrder"
    cURL    := SuperGetMV("FS_C020202",, "http://news.edata.com.br:9192/soap/IWebServiceInterface") //URL Homolog

    Begin Sequence

        //Verificar se uso e necessario
		If !lFswTeste
			oTWSDLMngr  := TWSDLManager():New()

			oTWSDLMngr:lProcResp     := .F.
            oTWSDLMngr:bNoCheckPeerCert := .T.

			If !(oTWSDLMngr:ParseURL(cURL))
				cMsgErro := "Erro: Arquivo WSDL informado invalido." + CRLF + AllTrim(oTWSDLMngr:cError)
				Break
			EndIf

			// Define a operacao
			If !(oTWSDLMngr:SetOperation(cMetodo))
				cMsgErro := "Erro: Nao foi possivel estabelecer a chamada do metodo " + cMetodo + "."
				Break
			EndIf

			// Autenticacao de usuario de integracao
			If !(Empty(cUsuario)) .And. !(Empty(cPassword))
				If !(oTWSDLMngr:SetAuthentication(cUsuario, cPassword))
					cMsgErro := "Erro: Nao foi possivel realizar autenticacao de usuario: " + CRLF + AllTrim(oTWSDLMngr:cError)
					Break
				EndIf
			EndIf
		Endif

		cFilPed := FwXFilial("SC5", aPedido[1][DEF_FILPED])

        SC5->(DbSetOrder(1))
        If !(SC5->(DbSeek( cFilPed + aPedido[1][DEF_PEDIDO])))
            cMsgErro := "Erro: Pedido de Venda nao encontrado na base de dados."
            Break
        EndIf

		If ( SC5->C5_TIPO $ "DB" )
			SA2->(DbSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
			If !(SA2->(DbSeek(FwXFilial("SA2", cFilPed) + SC5->C5_CLIENTE + SC5->C5_LOJACLI)))
				cMsgErro := "Erro: Fornecedor nao encontrado na base de dados."
				Break
			Else
				// localiza o cliente pelo CNPJ do fornecedor
				SA1->(DbSetOrder(3)) // A1_FILIAL+A1_CGC
				If !(SA1->(DbSeek(FwXFilial("SA1", cFilPed) + SA2->A2_CGC)))
					cMsgErro := "Erro: Cliente (CNPJ " + SA2->A2_CGC + ") nao encontrado na base de dados."
					Break
				EndIf
			EndIf
		Else
			SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
			If !(SA1->(DbSeek(FwXFilial("SA1", cFilPed) + SC5->C5_CLIENTE + SC5->C5_LOJACLI)))
				cMsgErro := "Erro: Cliente nao encontrado na base de dados."
				Break
			EndIf
		Endif
		
        cPaisDesc   := AllTrim(GetAdvFVal("SYA", "YA_DESCR", FwXFilial("SYA", aPedido[1][DEF_FILPED]) + SA1->A1_PAIS, 1, "", .T.))
        cEstDesc    := AllTrim(GetAdvFVal("SX5", "X5_DESCRI", FwXFilial("SX5", aPedido[1][DEF_FILPED]) + "12" + SA1->A1_EST, 1, "", .T.))
        cEstEDesc   := AllTrim(GetAdvFVal("SX5", "X5_DESCRI", FwXFilial("SX5", aPedido[1][DEF_FILPED]) + "12" + SA1->A1_ESTE, 1, "", .T.))

        SC6->(DbSetOrder(1))
        For nItem := 1 To Len(aPedido)
            If !(SC6->(DbSeek(FwXFilial("SC6", aPedido[nItem][DEF_FILPED]) + aPedido[nItem][DEF_PEDIDO] + aPedido[nItem][DEF_ITEMPE])))
                cMsgErro := "Erro: Itens do Pedido de Venda nao encontrados na base de dados."
                Break
            EndIf
			aAdd( aEnvAux, {;
							SC6->C6_FILIAL 	,; // 01
							SC6->C6_NUM 	,; // 02
							SC6->C6_ITEM 	,; // 03
							SC6->C6_PRODUTO	,; // 04
							SC6->C6_PRCVEN	,; // 05
							SC6->C6_UNSVEN	,; // 06
							SC6->C6_QTDVEN	,; // 07
							SC6->C6_VALOR 	 ; // 08
							} )
			dEntrega := SC6->C6_ENTREG
        Next nItem
		
		aEnvPedido := AgrEdata(aEnvAux, SC5->C5_FILIAL, SC5->C5_NUM) // agrupa produtos iguais para enviar ao eData (devido a limitação do eData para SKU único por pedido)

        cSOAPXML += "<?xml version='1.0' encoding='UTF-8' standalone='no' ?>" + CRLF
        cSOAPXML := '<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"' +;
            ' xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:WebServiceInterfaceInterface-IWebServiceInterface"' +;
            ' xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">' + CRLF
        cSOAPXML += '<soapenv:Header/>' + CRLF
        cSOAPXML += '<soapenv:Body>' + CRLF
        cSOAPXML += '   <urn:PostAddSalesOrder soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' + CRLF
        cSOAPXML += '      <InputParams xsi:type="urn:PostAddSalesOrderParams" xmlns:urn="urn:WebServiceClasses">' + CRLF
        cSOAPXML += '         <SalesOrderNo xsi:type="xsd:string">' +  SC5->C5_NUM + '</SalesOrderNo>' + CRLF
        cSOAPXML += '         <BranchNo xsi:type="xsd:int">' +  SC5->C5_FILIAL + '</BranchNo>' + CRLF
        cSOAPXML += '         <CustomerNo xsi:type="xsd:string">' +  SA1->A1_COD + SA1->A1_LOJA + '</CustomerNo>' + CRLF

        // Informacao de Entrega
        // Qualquer informação alterada no endereço de entrega deve ser replicada no WS PostAddCustomer (F0202301)
        cSOAPXML += '         <DeliveryAddress xsi:type="urn:AddressInfo">' + CRLF
        cSOAPXML += '            <AddressType xsi:type="xsd:string"></AddressType>' + CRLF 
        cSOAPXML += '            <Address xsi:type="xsd:string">' + StringXML(AllTrim(left(SA1->A1_ENDENT,40))) + '</Address>' + CRLF
        cSOAPXML += '            <Number xsi:type="xsd:string"></Number>' + CRLF 
        cSOAPXML += '            <District xsi:type="xsd:string">' + StringXML(AllTrim(left(SA1->A1_BAIRROE,30))) + '</District>' + CRLF
        cSOAPXML += '            <ZIPCode xsi:type="xsd:string">' + AllTrim(SA1->A1_CEPE) + '</ZIPCode>' + CRLF
        cSOAPXML += '            <City xsi:type="xsd:string">' + StringXML(AllTrim(left(SA1->A1_MUNE,40))) + '</City>' + CRLF
        cSOAPXML += '            <State xsi:type="xsd:string">' + StringXML(AllTrim(left(cEstEDesc,40))) + '</State>' + CRLF
        cSOAPXML += '            <StateInitials xsi:type="xsd:string">' + AllTrim(SA1->A1_ESTE) + '</StateInitials>' + CRLF
        cSOAPXML += '            <Country xsi:type="xsd:string">' + StringXML(AllTrim(left(cPaisDesc,40))) + '</Country>' + CRLF
        cSOAPXML += '         </DeliveryAddress>' + CRLF

        // Informacao de Cobranca
        // Qualquer informação alterada no endereço de entrega deve ser replicada no WS PostAddCustomer (F0202301)
        cSOAPXML += '         <BillingAddress xsi:type="urn:AddressInfo">' + CRLF
        cSOAPXML += '            <AddressType xsi:type="xsd:string"></AddressType>' + CRLF //Nao encontrado no WSDL eData da MIT
        cSOAPXML += '            <Address xsi:type="xsd:string">' + StringXML(AllTrim(left(SA1->A1_END,40))) + '</Address>' + CRLF
        cSOAPXML += '            <Number xsi:type="xsd:string"></Number>' + CRLF //Nao encontrado no WSDL eData da MIT
        cSOAPXML += '            <District xsi:type="xsd:string">' + StringXML(AllTrim(left(SA1->A1_BAIRRO,30))) + '</District>' + CRLF
        cSOAPXML += '            <ZIPCode xsi:type="xsd:string">' + AllTrim(SA1->A1_CEP) + '</ZIPCode>' + CRLF
        cSOAPXML += '            <City xsi:type="xsd:string">' + StringXML(AllTrim(left(SA1->A1_MUN,40))) + '</City>' + CRLF
        cSOAPXML += '            <State xsi:type="xsd:string">' + StringXML(AllTrim(left(cEstDesc,40))) + '</State>' + CRLF
        cSOAPXML += '            <StateInitials xsi:type="xsd:string">' + AllTrim(SA1->A1_EST) + '</StateInitials>' + CRLF
        cSOAPXML += '            <Country xsi:type="xsd:string">' + StringXML(AllTrim(left(cPaisDesc,40))) +'</Country>' + CRLF
        cSOAPXML += '         </BillingAddress>' + CRLF

        If SC5->C5_TPFRETE $ "CF"
            If SC5->C5_TPFRETE == "C"
                cTipoFrete :=  "ftShipper"
            Else
                cTipoFrete :=  "ftRemittee"
            EndIf
        EndIf

        cSOAPXML += '         <SellerNo xsi:type="xsd:string">' +  SC5->C5_VEND1 + '</SellerNo>' + CRLF
        cSOAPXML += '         <SalesOrderDate xsi:type="xsd:dateTime">' + FwTimeStamp(3,SC5->C5_EMISSAO) + '</SalesOrderDate>' + CRLF
        cSOAPXML += '         <RegisterDate xsi:type="xsd:dateTime">' +  FwTimeStamp(3,SC5->C5_EMISSAO) + '</RegisterDate>' + CRLF
        cSOAPXML += '         <DeliveryDate xsi:type="xsd:dateTime">' +  FwTimeStamp(3,dEntrega) + '</DeliveryDate>' + CRLF
        cSOAPXML += '         <FreightType xsi:type="urn:FreightType">' + cTipoFrete + '</FreightType>' + CRLF
        cSOAPXML += '         <LoadNo xsi:type="xsd:string"></LoadNo>' + CRLF
        cSOAPXML += '         <Notes xsi:type="xsd:string">' +  FwNoAccent(SC5->C5_XOBSPED) + '</Notes>' + CRLF

        //Itens do Pedido de Venda
        cSOAPXML += '         <ItemList xsi:type="urn:AddSalesOrderItemList" soapenc:arrayType="urn:AddSalesOrderItem[]">' + CRLF
        For nItem := 1 To Len(aEnvPedido)
			cSOAPXML += '		<AddSalesOrderItem xsi:type="urn:Array">' + CRLF 
			cSOAPXML += '   		<ItemNo xsi:type="xsd:string">' +  aEnvPedido[nItem][03] + '</ItemNo>' + CRLF
			cSOAPXML += '   		<ProductNo xsi:type="xsd:string">' +  Alltrim(aEnvPedido[nItem][04]) + '</ProductNo>' + CRLF
			cSOAPXML += '   		<UnitValue xsi:type="xsd:double">' +  CValToChar(aEnvPedido[nItem][05]) + '</UnitValue>' + CRLF
			cSOAPXML += '   		<Qty xsi:type="xsd:int">' +  CValToChar(aEnvPedido[nItem][06]) + '</Qty>' + CRLF
			cSOAPXML += '   		<Weight xsi:type="xsd:double">' +  CValToChar(aEnvPedido[nItem][07]) + '</Weight>' + CRLF
			cSOAPXML += '   		<TotalValue xsi:type="xsd:double">' +  CValToChar(aEnvPedido[nItem][08]) + '</TotalValue>' + CRLF
			cSOAPXML += '		</AddSalesOrderItem>'
        Next nItem
        cSOAPXML += '         </ItemList>' + CRLF

        cSOAPXML += '      </InputParams>' + CRLF
        cSOAPXML += '   </urn:PostAddSalesOrder>' + CRLF
        cSOAPXML += '</soapenv:Body>' + CRLF
        cSOAPXML += '</soapenv:Envelope>' + CRLF

		If !lFswTeste
			//Valida se a requisicao foi montada e enviada com sucesso ao server
			If !(oTWSDLMngr:SendSoapMsg(cSOAPXML))
				cMsgErro := "Erro: " + cMetodo + " - Erro ao enviar requisicao ao servidor " + oTWSDLMngr:cError
				Break
			Else
				cSOAPRet    := oTWSDLMngr:GetSoapResponse()

				oXML := XMLParser(cSOAPRet, "_", @cErro, @cAviso)

				If oXML == Nil
					cMsgErro := "Erro: " + cErro
					Break
				Endif
				// Converte as tags de um XML em array {cName, cText}
				aSOAPRet := XmlToArr(cSOAPRet, {'STATUS','MESSAGE','FAULTSTRING','SALESORDERCODE','ERRORCODE'}) 
				
				nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "STATUS" } ) 
				If nPosSOAPRet > 0 .and. upper(alltrim(aSOAPRet[nPosSOAPRet][2])) == "WRSSUCCESS" 
					nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "SALESORDERCODE" } ) 
					If nPosSOAPRet > 0
						nPedVeData 	:= Val(alltrim(aSOAPRet[nPosSOAPRet][2])) 
					Endif    
					Break
				Endif

				nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "ERRORCODE" } ) 
				cErrorCode := ""
				If nPosSOAPRet > 0
					cErrorCode := upper(alltrim(aSOAPRet[nPosSOAPRet][2]))
				EndIf

				nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "MESSAGE" } ) // falha
				If nPosSOAPRet > 0
					If !Empty(cErrorCode)
						cMsgErro := cErrorCode + " - " + upper(alltrim(aSOAPRet[nPosSOAPRet][2]))
					else
						cMsgErro := upper(alltrim(aSOAPRet[nPosSOAPRet][2]))                    
					Endif
					Break
				EndIf
				
				nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "FAULTSTRING" } ) // falha
				If nPosSOAPRet > 0
					cMsgErro := upper(alltrim(aSOAPRet[nPosSOAPRet][2]))
				Else
					cMsgErro := "Erro não identificado ao enviar o cancelamento para o eData"
				Endif
			EndIf
		Endif
    End Sequence

	If !lFswTeste
		If !(Empty(cMsgErro))
			lEnvSucess := .F.
			U_F07Log03("EnvPdVenda", oXML, cMsgErro, "1", "SC5", 1, SC5->C5_FILIAL + SC5->C5_NUM) // Falha
		EndIf

		FwFreeObj(oXML)
		FwFreeObj(oTWSDLMngr)
	Endif
	
    AEval(aArea, {|area| RestArea(area)})

	If !lFswTeste
		aRet := {lEnvSucess, cMsgErro, nPedVeData}
	Else
		aRet := {lEnvSucess, cMsgErro, nPedVeData, cSOAPXML}	
	Endif
	
Return aRet

//Exemplo de XML - PostAddSalesOrder
/*
<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" +;
xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" +;
xmlns:urn="urn:WebServiceInterfaceInterface-IWebServiceInterface">
<soapenv:Header/>
<soapenv:Body> 
    <urn:PostAddSalesOrderResponse soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <return xsi:type="urn:PostAddSalesOrderReturn" xmlns:urn="urn:WebServiceClasses">
            <WebServiceReturn xsi:type="urn1:WebServiceReturn" xmlns:urn1="urn:WebServiceBase">
                <Status xsi:type="urn1:WebServiceReturnStatus">wrsSuccess</Status>
                <ErrorCode xsi:type="xsd:string"></ErrorCode>
                <Message xsi:type="xsd:string"></Message>
                <Actor xsi:type="xsd:string"></Actor>
                <ReturnQuestion xsi:type="urn1:ReturnQuestion">
                    <Code xsi:type="xsd:string"></Code>
                    <Message xsi:type="xsd:string"></Message>
                    <DialogType xsi:type="urn2:DialogType" xmlns:urn2="urn:CommonQuestionList"></DialogType>
                    <AbortAnswer xsi:type="urn2:AnswerType" xmlns:urn2="urn:CommonQuestionList"></AbortAnswer>
                </ReturnQuestion>
            </WebServiceReturn>
            <SalesOrderCode xsi:type="xsd:long">1</SalesOrderCode>
        </return>
    </urn:PostAddSalesOrderResponse>
</soapenv:Body>
</soapenv:Envelope>
*/

/*/{Protheus.doc} EnvCargaPV
Rotina localizada no botao 'Enviar Carregamento eData' na tela de pesagem.

@type       Static Function
@author     Rafael Riego
@since      16/09/2019
@param      aPedido, array, array contendo todos os itens do pedido de venda
@return     Nil
/*/
Static Function EnvCargaPV(aPedido)

    Local aArea         := {}

    Local cAviso        := ""
    Local cErro         := ""
    Local cMetodo       := ""
    Local cMsgErro      := ""
    Local cPedidos      := ""
    Local cPassword     := ""
    Local cSOAPRet      := ""
    Local cSOAPXML      := ""
    Local cURL          := ""
    Local cUsuario      := ""
    Local lEnvSucess    := .T.
    Local nCargaData    := 0
    Local oTWSDLMngr    := Nil
    Local oXML          := Nil
    Local cPlaca        := ""		//Anderson Gomes
    Local cCodMot       := ""		//Anderson Gomes
    Local cTransp       := ""		//Anderson Gomes
    Local cObsPed       := ""
    Local aObsPed
    Local nItem
    Local nI
    Local nX


    Local aSOAPRet      := ""
    Local nPosSOAPRet   := ""

    aArea   := {SC5->(GetArea()), SC6->(GetArea()), SA1->(GetArea()), SYA->(GetArea()), SX5->(GetArea()), GetArea()}

    cMetodo := "PostAddLoad"
    cURL    := SuperGetMV("FS_C020202",, "http://news.edata.com.br:9192/soap/IWebServiceInterface") //URL Homolog

    Begin Sequence

        //Posiciona no 1o pedido do array
        SC5->(DbSetOrder(1))
        If !(SC5->(DbSeek(FwXFilial("SC5", aPedido[1][1][DEF_FILPED]) + aPedido[1][1][DEF_PEDIDO])))
            cMsgErro := "Erro: Pedido de Venda nao encontrado na base de dados."
            Break
        EndIf

        DA3->(DbSetOrder(3))
        cPlaca  := IIF(EMPTY(DK0->DK0_PLACA),PC2->PC2_PLACA,DK0->DK0_PLACA) 		// Anderson Gomes
        cCodMot := PC2->PC2_MOTOR

        If !(DA3->(DbSeek(FwXFilial("DA3", aPedido[1][1][DEF_FILPED]) + AvKey(cPlaca, "DA3_PLACA"))))		//Anderson Gomes
            cMsgErro := "Erro: Placa do veiculo nao encontrado no sistema."
            Break
        ElseIf Empty(cCodMot)		//Anderson Gomes
            cMsgErro := "Erro: Motorista nao vinculado ao veiculo informado."
            Break
        EndIf

		U_F041003A(cCodMot) // Envio de motoristas ao eData - PostAddDriver

        //Verificar se uso e necessario
        oTWSDLMngr  := TWSDLManager():New()

        oTWSDLMngr:lProcResp     := .F.
        oTWSDLMngr:bNoCheckPeerCert := .T.

        If !(oTWSDLMngr:ParseURL(cURL))
            cMsgErro := "Erro: Arquivo WSDL informado invalido." + CRLF + AllTrim(oTWSDLMngr:cError)
            Break
        EndIf

        // Define a operacao
        If !(oTWSDLMngr:SetOperation(cMetodo))
            cMsgErro := "Erro: Nao foi possivel estabelecer a chamada do metodo " + cMetodo + "."
            Break
        EndIf

        // Autenticacao de usuario de integracao
        If !(Empty(cUsuario)) .And. !(Empty(cPassword))
            If !(oTWSDLMngr:SetAuthentication(cUsuario, cPassword))
                cMsgErro := "Erro: Nao foi possivel realizar autenticacao de usuario: " + CRLF + AllTrim(oTWSDLMngr:cError)
                Break
            EndIf
        EndIf

        aObsPed := {}
        For nItem := 1 To Len(aPedido)
            cPedidos += '<AddLoadSalesOrderItem xsi:type="urn:Array">' + CRLF  //TODO - verificar se o nome da tag estao correta
            cPedidos += '   <SalesOrderNo xsi:type="xsd:string">' + aPedido[nItem][1][DEF_PEDIDO] + '</SalesOrderNo>' + CRLF
            cPedidos += '</AddLoadSalesOrderItem>'            
            IF (nPos := Ascan(aObsPed, { |x| x[1] == aPedido[nItem][1][DEF_PEDIDO] })) == 0
	            IF SC5->(DbSeek(FwXFilial("SC5", aPedido[nItem][1][DEF_FILPED]) + aPedido[nItem][1][DEF_PEDIDO])) .And. !Empty(SC5->C5_X_V_RM)
	               AAdd(aObsPed,{"Pedido: "+aPedido[nItem][1][DEF_PEDIDO]," Obs.: "+FwNoAccent(StringXML(SC5->C5_X_V_RM))+ CRLF})
	            Endif
	        Endif
        Next nPedido
        
        //Aglutinar numero de pedidos com a mesma observação
        For nI:= 1 to Len(aObsPed)
          For nX:= 1 to Len(aObsPed)
            if (aPedido[nI][1][2] <> aPedido[nX][1][2]) .and. (aObsPed[nI,2] $ aObsPed[nX,2])
            aObsPed[nI,1] += ","+aPedido[nX][1][2]
            aObsPed[nX,1] := ""
            aObsPed[nX,2] := ""
            endif
          Next
        Next

        cObsPed := ""
        For nI:= 1 To Len(aObsPed)
            cObsPed += aObsPed[nI,1]
            if !Empty(aObsPed[nI,2])
        	cObsPed += aObsPed[nI,2] + CRLF
            Endif
        Next

        cTransp := IIF(EMPTY(Alltrim(DK0->DK0_TRANSP)),PC2->PC2_TRANSP,LimpTrans(Alltrim(DK0->DK0_TRANSP)))		//Anderson Gomes

        cSOAPXML := "<?xml version='1.0' encoding='UTF-8' standalone='no' ?>" + CRLF
        cSOAPXML += '<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"'+;
            ' xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:WebServiceInterfaceInterface-IWebServiceInterface"' +;
            ' xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">' + CRLF
        cSOAPXML += '<soapenv:Header/>' + CRLF
        cSOAPXML += '<soapenv:Body>' + CRLF
        cSOAPXML += '    <urn:PostAddLoad soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' + CRLF
        cSOAPXML += '        <InputParams xsi:type="urn:PostAddLoadParams" xmlns:urn="urn:WebServiceClasses">' + CRLF
        cSOAPXML += '            <LoadNo xsi:type="xsd:string">' + AllTrim(DK0->DK0_VIAGID) + '</LoadNo>' + CRLF
        cSOAPXML += '            <BranchNo xsi:type="xsd:int">' + SC5->C5_FILIAL + '</BranchNo>' + CRLF
        cSOAPXML += '            <LoadDate xsi:type="xsd:dateTime">' + FwTimeStamp(3,DK0->DK0_XDTCAR) + '</LoadDate>' + CRLF  //DK0->DK0_XDTCAR
        cSOAPXML += '            <RoutingDate xsi:type="xsd:dateTime">' + FwTimeStamp(3,DK0->DK0_DATINT) + '</RoutingDate>' + CRLF
        cSOAPXML += '            <VehiclePlateNo xsi:type="xsd:string">' + AllTrim(cPlaca) + '</VehiclePlateNo>' + CRLF		//Anderson Gomes
        cSOAPXML += '            <Blocked xsi:type="xsd:boolean">false</Blocked>' + CRLF //testar
        cSOAPXML += '            <Notes xsi:type="xsd:string">' +  cObsPed + '</Notes>' + CRLF
        cSOAPXML += '            <LoadType xsi:type="urn:LoadType">ltTotalized</LoadType>' + CRLF //Verificar se esta correto
        //cSOAPXML += '            <DispatchingDate xsi:type="xsd:dateTime"></DispatchingDate>' + CRLF		//Anderson Gomes
        cSOAPXML += '            <DriverNo xsi:type="xsd:string">' + AllTrim(cCodMot) + '</DriverNo>' + CRLF		//Anderson Gomes
        cSOAPXML += '            <TransporterNo xsi:type="xsd:string">' + AllTrim(cTransp) + '</TransporterNo>' + CRLF		//Anderson Gomes
        //cSOAPXML += '            <ShippingType xsi:type="urn:ShippingType"></ShippingType>' + CRLF 		//Anderson Gomes
        //cSOAPXML += '            <ContainerNo xsi:type="xsd:string"></ContainerNo>' + CRLF 		//Anderson Gomes
        //cSOAPXML += '            <LoadGroupNo xsi:type="xsd:string"></LoadGroupNo>' + CRLF //nao esta na MIT 		//Anderson Gomes
        cSOAPXML += '            <SalesOrderList xsi:type="urn:AddLoadSalesOrderItemList" soapenc:arrayType="urn:AddLoadSalesOrderItem[]">' + CRLF
        cSOAPXML += cPedidos
        cSOAPXML += '            </SalesOrderList>'
        cSOAPXML += '        </InputParams>' + CRLF
        cSOAPXML += '    </urn:PostAddLoad>' + CRLF
        cSOAPXML += '</soapenv:Body>' + CRLF
        cSOAPXML += '</soapenv:Envelope>' + CRLF

        //Valida se a requisicao foi montada e enviada com sucesso ao server
        If !(oTWSDLMngr:SendSoapMsg(cSOAPXML))
            cMsgErro := "Erro: " + cMetodo + " - Erro ao enviar requisicao ao servidor " + oTWSDLMngr:cError
            Break
        Else
            cSOAPRet    := oTWSDLMngr:GetSoapResponse()

            oXML := XMLParser(cSOAPRet, "_", @cErro, @cAviso)

            If oXML == Nil
                cMsgErro := "Erro: " + cErro
                Break
            Endif
            // Converte as tags de um XML em array {cName, cText}
            aSOAPRet := XmlToArr(cSOAPRet, {'STATUS','MESSAGE','FAULTSTRING','LOADCODE'}) 
            nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "STATUS" } ) 
            If nPosSOAPRet > 0 .and. upper(alltrim(aSOAPRet[nPosSOAPRet][2])) == "LOADCODE" 
                nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "LOADCODE" } ) 
                If nPosSOAPRet > 0
                    nCargaData 	:= Val(alltrim(aSOAPRet[nPosSOAPRet][2])) 
                Endif    
                Break
            Endif
            nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "MESSAGE" } ) // falha
            If nPosSOAPRet > 0
                cMsgErro := upper(alltrim(aSOAPRet[nPosSOAPRet][2]))
                Break
            EndIf
            nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "FAULTSTRING" } ) // falha
            If nPosSOAPRet > 0
                cMsgErro := upper(alltrim(aSOAPRet[nPosSOAPRet][2]))
            Else
                cMsgErro := "Erro não identificado ao enviar o cancelamento para o eData"
            Endif

        EndIf
    End Sequence

    If !(Empty(cMsgErro))
        lEnvSucess := .F.
        U_F07Log03("EnvCargaPV", oXML, cMsgErro, "1", "SC5", 1, SC5->C5_FILIAL + SC5->C5_NUM) // Falha
    EndIf

    FwFreeObj(oXML)
    FwFreeObj(oTWSDLMngr)

    AEval(aArea, {|area| RestArea(area)})

Return {lEnvSucess, cMsgErro, nCargaData}

//<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
//xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:WebServiceInterfaceInterface-IWebServiceInterface" 
//xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">
//   <soapenv:Header/>
//   <soapenv:Body>
//      <urn:PostAddLoad soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
//         <InputParams xsi:type="urn:PostAddLoadParams" xmlns:urn="urn:WebServiceClasses">
//            <LoadNo xsi:type="xsd:string">?</LoadNo>
//            <BranchCode xsi:type="xsd:int">?</BranchCode>
//            <LoadDate xsi:type="xsd:dateTime">?</LoadDate>
//            <RoutingDate xsi:type="xsd:dateTime">?</RoutingDate>
//            <VehiclePlateNo xsi:type="xsd:string">?</VehiclePlateNo>
//            <Blocked xsi:type="xsd:boolean">?</Blocked>
//            <Notes xsi:type="xsd:string">?</Notes>
//            <LoadType xsi:type="urn:LoadType">?</LoadType>
//            <DispatchingDate xsi:type="xsd:dateTime">?</DispatchingDate>
//            <DriverNo xsi:type="xsd:string">?</DriverNo>
//            <TransporterNo xsi:type="xsd:string">?</TransporterNo>
//            <ShippingType xsi:type="urn:ShippingType">?</ShippingType>
//            <ContainerNo xsi:type="xsd:string">?</ContainerNo>
//            <LoadGroupNo xsi:type="xsd:string">?</LoadGroupNo>
//            <SalesOrderList xsi:type="urn:AddLoadSalesOrderItemList" soapenc:arrayType="urn:AddLoadSalesOrderItem[]"/>
//         </InputParams>
//      </urn:PostAddLoad>
//   </soapenv:Body>
//</soapenv:Envelope>

/*/{Protheus.doc} F0202003
Envio de Fechamento de Carga par ao sistema eData.

@type       User Function
@author     Rafael Riego
@since      16/09/2019
@param      aPedido, array, numeros dos pedidos de venda que fazem parte da carga
@return     Nil
/*/
User Function F0202003(aPedidos)

    Local aArea         := {}

    Local cAviso        := ""
    Local cErro         := ""
    Local cMetodo       := ""
    Local cMsgErro      := ""
    Local cPassword     := ""
    Local cSOAPRet      := ""
    Local cSOAPXML      := ""
    Local cURL          := ""
    Local cUsuario      := ""
    Local lEnvSucess    := .T.
    Local oTWSDLMngr    := Nil
    Local oXML          := Nil
    Local aSOAPRet      := ""
    Local nPosSOAPRet   := ""

    Default cFilPed     := ""
    Default cPedido     := ""

    aArea   := {GetArea()}

    cMetodo := "PostLoadClosure"
    cURL    := SuperGetMV("FS_C020202",, "http://news.edata.com.br:9192/soap/IWebServiceInterface") //URL Homolog

    Begin Sequence

        //Verificar se uso e necessario
        oTWSDLMngr  := TWSDLManager():New()

        oTWSDLMngr:lProcResp     := .F.
        oTWSDLMngr:bNoCheckPeerCert := .T.
        
        If !(oTWSDLMngr:ParseURL(cURL))
            cMsgErro := "Erro: Arquivo WSDL informado invalido." + CRLF + AllTrim(oTWSDLMngr:cError)
            Break
        EndIf

        // Define a operacao
        If !(oTWSDLMngr:SetOperation(cMetodo))
            cMsgErro := "Erro: Nao foi possivel estabelecer a chamada do metodo " + cMetodo + "."
            Break
        EndIf

        // Autenticacao de usuario de integracao
        If !(Empty(cUsuario)) .And. !(Empty(cPassword))
            If !(oTWSDLMngr:SetAuthentication(cUsuario, cPassword))
                cMsgErro := "Erro: Nao foi possivel realizar autenticacao de usuario: " + CRLF + AllTrim(oTWSDLMngr:cError)
                Break
            EndIf
        EndIf

        cSOAPXML += "<?xml version='1.0' encoding='UTF-8' standalone='no' ?>" + CRLF
        cSOAPXML := '<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' +;
            ' xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:WebServiceInterfaceInterface-IWebServiceInterface" ' +;
            ' xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">' + CRLF
        cSOAPXML += '<soapenv:Header/>' + CRLF
        cSOAPXML += '<soapenv:Body>' + CRLF
        cSOAPXML += '<urn:PostLoadClosure soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        cSOAPXML += '    <InputParams xsi:type="urn:PostLoadClosureParams" xmlns:urn="urn:WebServiceClasses">'
        cSOAPXML += '        <LoadNo xsi:type="xsd:string">' + alltrim(DK0->DK0_VIAGID) + '</LoadNo>'		//Anderson Gomes
        cSOAPXML += '        <BranchNo xsi:type="xsd:int">' + PC2->PC2_FILIAL + '</BranchNo>'		//Anderson Gomes
        cSOAPXML += '    </InputParams>'
        cSOAPXML += '</urn:PostLoadClosure>'
        cSOAPXML += '</soapenv:Body>' + CRLF
        cSOAPXML += '</soapenv:Envelope>' + CRLF

        //Valida se a requisicao foi montada e enviada com sucesso ao server
        If !(oTWSDLMngr:SendSoapMsg(cSOAPXML))
            cMsgErro := "Erro: " + cMetodo + " - Erro ao enviar requisicao ao servidor " + oTWSDLMngr:cError
            Break
        Else
            cSOAPRet    := oTWSDLMngr:GetSoapResponse()

            oXML := XMLParser(cSOAPRet, "_", @cErro, @cAviso)

            If oXML == Nil
                cMsgErro := "Erro: " + cErro
                Break
            Endif
            // Converte as tags de um XML em array {cName, cText}
            aSOAPRet := XmlToArr(cSOAPRet, {'STATUS','MESSAGE','FAULTSTRING'}) 
            nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "STATUS" } ) 
            If nPosSOAPRet > 0 .and. upper(alltrim(aSOAPRet[nPosSOAPRet][2])) == "WRSSUCCESS" 
                // nada faz
            Endif
            nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "MESSAGE" } ) // falha
            If nPosSOAPRet > 0
                cMsgErro := upper(alltrim(aSOAPRet[nPosSOAPRet][2]))
                Break
            EndIf
            nPosSOAPRet := aScan( aSOAPRet, {|x| upper(alltrim(x[1])) == "FAULTSTRING" } ) // falha
            If nPosSOAPRet > 0
                cMsgErro := upper(alltrim(aSOAPRet[nPosSOAPRet][2]))
            Else
                cMsgErro := "Erro não identificado ao enviar o cancelamento para o eData"
            Endif

        EndIf
    End Sequence

    If !(Empty(cMsgErro))
        lEnvSucess := .F.
        If InTransact()
            DisarmTransaction()
        EndIf
        U_F07Log03("U_F0202003", oXML, cMsgErro, "1", "DK0", 1, DK0->DK0_FILIAL + DK0->DK0_VIAGID) // Falha
        Aviso("Carga eData", cMsgErro, {"Fechar"}, 1)
    Else
        Aviso("Carga eData", "Fechamento de Carga eData efetuado com sucesso.", {"Fechar"}, 1)
    EndIf

    FwFreeObj(oXML)
    FwFreeObj(oTWSDLMngr)

    AEval(aArea, {|area| RestArea(area)})

Return {lEnvSucess, cMsgErro}


/*/{Protheus.doc} AgrEdata

Agrupa produtos iguais para enviar ao eData 
Devido a limitação do eData para SKU único por pedido

aAdd( aEnvAux, {;
				SC6->C6_FILIAL 	,; // 01 
				SC6->C6_NUM 	,; // 02 
				SC6->C6_ITEM 	,; // 03 
				SC6->C6_PRODUTO	,; // 04 
				SC6->C6_PRCVEN	,; // 05 
				SC6->C6_UNSVEN	,; // 06 
				SC6->C6_QTDVEN	,; // 07 
				SC6->C6_VALOR 	 ; // 08 
				} )

@type       Static Function
@author     Fabio Cazarini
@since      07/11/2020
@param      aEnvAux, array com os itens a agrupar
@param      cFilPed, filial do pedido
@param      cPedido, número do pedido
@return     aRet, array com os itens agrupados
/*/
Static Function AgrEdata(aEnvAux, cFilPed, cPedido)
	Local aAreaPD6	:= PD6->( GetArea() )
	Local aRet 		:= {}
	Local nX		:= 0
	Local cProduto	:= ""
	Local nPosProd	:= 0
	Local cItemOrig	:= ""
	Local cItemEnv	:= ""
	
	// exclui a tabela intermediária (de->para Protheus vs eData) anterior
	PD6->( DbSetOrder(1) ) // PD6_FILIAL+PD6_FILPED+PD6_PEDIDO+PD6_ITEMEN
	If PD6->( DbSeek( xFilial("PD6")+cFilPed+cPedido  ) )
		Do While PD6->( !Eof() ) .and.;
				 PD6->( PD6_FILIAL+PD6_FILPED+PD6_PEDIDO ) == ( xFilial("PD6")+cFilPed+cPedido )
		
			RecLock("PD6", .F. )
			PD6->( DbDelete() )
			
			PD6->( DbSkip() )
		Enddo
	Endif
	
	For nX := 1 To Len(aEnvAux)
		cItemOrig	:= aEnvAux[nX][03]
		cProduto	:= aEnvAux[nX][04]
		cItemEnv 	:= cItemOrig
		
		nPosProd := aScan( aRet, { |x| x[04] == cProduto } )
		If nPosProd = 0
			aAdd( aRet, aEnvAux[nX] )
		Else
			// Item (C6_ITEM) a enviar 
			cItemEnv := aRet[nPosProd][03]

			// acumula quantidade, peso e valor
			aRet[nPosProd][06] += aEnvAux[nX][06]
			aRet[nPosProd][07] += aEnvAux[nX][07]
			aRet[nPosProd][08] += aEnvAux[nX][08]
		Endif

		// cria registro na tabela intermediária (de->para Protheus vs eData)
		RecLock("PD6", .T. )
			PD6->PD6_FILIAL	:= xFilial("PD6")
			PD6->PD6_FILPED	:= cFilPed
			PD6->PD6_PEDIDO	:= cPedido
			PD6->PD6_ITEM	:= cItemOrig
			PD6->PD6_ITEMEN	:= cItemEnv
			PD6->PD6_PRODUT	:= cProduto
			PD6->PD6_QTDVEN	:= aEnvAux[nX][07]
            PD6->PD6_QTDREC	:= 0
		PD6->( MsUnlock() )
	Next nX
	
	RestArea(aAreaPD6)
	
Return aRet


/*/{Protheus.doc} LimpTrans
    (Funcao criada para tratar a transportadora na DKO que vem com o "-" e a unidade de negocio)
    @type  Static Function
    @author Anderson Gomes
    @since 07/12/2019
    @version version
/*/

Static Function LimpTrans(cTransp)
    
    Local cRetTran   := cTransp
    Local nLenGrpCmp := 0
    Local nSizeFil   := 0
    Local nPosTran   := AT('-', cTransp)
    

    If !Empty(cTransp)
        If Empty(OsCplEmpDef()) .And. !OsHasEmpFil()
            nLenGrpCmp := Len(FWGrpCompany())
        EndIf
        // Se o modo de compartilhamento da tabela de transportadores for exclusiva
        If FwModeAccess("SA4") == "E"
            nSizeFil := FWSizeFilial()
        EndIf
        //Ajusta string da transportadora para remover a referencia da empresa e filial 
        cTransp := SubStr(cTransp,1,IIF(nPosTran > 0, nPosTran-1, Len(cTransp)))
        //Valida se transportadora e valida, para entao gravar na carga
        SA4->(DbSetOrder(1))
        If !SA4->(dbSeek(xFilial('SA4')+cTransp))
            cTransp := ""
        EndIf
        cRetTran   := cTransp
    EndIf


Return cRetTran


/*/{Protheus.doc} XmlToArr

Converte as tags de um XML em array {cName, cText}

@type function
@version 
@author fabio.cazarini
@since 08/07/2020
@param cXML, character, XML para ser parseado
@param aTags, array, Array com as tags que devem ser retornadas 
@return array, array com o nome (CNAME) e conteúdo (CTEXT) das tags enviadas no parâmetro aTags
/*/
Static Function XmlToArr(cXML, aTags)
    Local aRet  := {}
    Local xRet
    Local lLoop := .T.
    Local lRet1 := .F.
    Local lRet2 := .F.
    Local oXML := TXmlManager():New()
    
    xRet := oXML:Parse( cXML )
    if xRet == .F.
        Return aRet
    endif

    while lLoop
        If aScan( aTags, {|x| upper(alltrim(x)) == upper(alltrim(oXML:CNAME)) } ) 
            aadd( aRet, {oXML:CNAME, oXML:CTEXT} )
        Endif    

        if oXML:DOMHasChildNode()
            xRet := oXML:DOMChildNode()
        elseif oXML:DOMHasNextNode()
            xRet := oXML:DOMNextNode()
        else
            lRet1 := oXML:DOMParentNode()
            if lRet1
                lRet2 := oXML:DOMNextNode()
                    
                while !lRet2
                    lRet1 := oXML:DOMParentNode()
                    lRet2 := oXML:DOMNextNode()
                    
                    if !lRet1 .And. !lRet2
                        Return aRet
                    endif
                enddo
                   
                loop
            else
                Return aRet
            endif
        endif
        if !xRet
            Return aRet
        endif
    enddo

Return aRet


/*/{Protheus.doc} StringXML
Substitui caracteres especiais reservados no XML

@type       Static Function
@author     Fabio Cazarini
@since      15/11/2019
@param      cString, string com a palavra 
@return     cRet, string com caracteres especiais tratados
/*/
Static Function StringXML(cString)
    Local cRet := FwNoAccent(cString)

    cRet := Strtran(cRet,"&","&amp;")
    cRet := Strtran(cRet,"<","&lt;")
    cRet := Strtran(cRet,">","&gt;")
    cRet := Strtran(cRet,"º","")
    cRet := Strtran(cRet,"°","")
    cRet := Strtran(cRet,"–","-")
    cRet := Strtran(cRet,"¼","")
    

Return cRet


/*/{Protheus.doc} F02020X1

Teste automatizado FSW

Exemplo:

U_F02020X1("Frigorificado", "53011")

@type       Static Function
@author     Fabio Cazarini
@since      07/11/2020
@param      None
@return     aRet, retorno do teste automatizado
/*/
User Function F02020X1(cRegID, cViagID)
	Local aRet 		:= {}
	Local lFswTeste	:= .T.
	Local cSeek		:= ""
	Local lAadd		:= .T.
	Local nPedidos	:= 0
	Local nPosPed	:= 0
    Local nPedido   := 0
    Local aPedidos  := {}
    Local nX        := 0
	Local aRet1     := {}
    
	// monta cenário de teste
    SC5->(DbSetOrder(1))
    DK0->(DbSetOrder(1))
	DK1->(DbSetOrder(1))
	
    cRegID  := Padr(cRegID, LEN(DK0->DK0_REGID) )
    cViagID := Padr(cViagID, LEN(DK1->DK1_VIAGID) )

    cSeek := FWxFilial("DK0") + cRegID + cViagID
    If DK0->(DbSeek(cSeek)) .and. DK1->(DbSeek(cSeek)) //Posiciona no 1o item da viagem
        While !DK1->(EoF()) .And. cSeek ==  (DK1->DK1_FILIAL+DK1->DK1_REGID+DK1->DK1_VIAGID)
            //Valida se a permitido o envio (se permitido caso seja de integracao eData)
            SC5->(DbSeek(FwXFilial(DK1->DK1_FILPED + DK1->DK1_PEDIDO)))
            //If !(U_F0202001()) 
            //If DK1->DK1_PEDIDO <> "000011"
            //    DK1->(DbSkip())
            //    Loop
            //EndIf

            lAadd := .F.
            
            If Empty(aPedidos)
                AAdd(aPedidos, {{DK1->DK1_FILPED, DK1->DK1_PEDIDO, DK1->DK1_ITEMPE, DK0->DK0_CARGA, DK0->DK0_REGID, DK1->DK1_VIAGID}})
            Else
                nPedidos := Len(aPedidos)
                For nPedido := 1 To nPedidos
                    nPosPed := AScan(aPedidos[nPedido], {|x| x[DEF_FILPED] + x[DEF_PEDIDO] == DK1->DK1_FILPED + DK1->DK1_PEDIDO})
                    If nPosPed > 0
                        AAdd(aPedidos[nPedido], {DK1->DK1_FILPED, DK1->DK1_PEDIDO, DK1->DK1_ITEMPE, DK0->DK0_CARGA,DK0->DK0_REGID,;
                            DK1->DK1_VIAGID})
                        lAadd := .F.
                    Else
                        lAadd := .T.
                    EndIf
                Next nPedido
                IF lAadd
                    AAdd(aPedidos, {{DK1->DK1_FILPED, DK1->DK1_PEDIDO, DK1->DK1_ITEMPE, DK0->DK0_CARGA, DK0->DK0_REGID, DK1->DK1_VIAGID}})
                Endif
            EndIf
            DK1->(DbSkip())
        End
	Endif
	
	If Len(aPedidos) > 0
        For nX := 1 To Len(aPedidos)
            aRet1 := EnvPdVenda(aPedidos[nX], lFswTeste)
            aadd(aRet, aRet1)
        Next nX
	Else
		aRet := {"viagem não localizada"}
	Endif	
	
Return aRet

Static Function VersaoGT()
	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)
	
	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL
	
	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10) 
	cTexto += "======  =================  =======  ======== " + CHR(10)
    cTexto += "003.0   MAX MIGUEL         147438   04/04/23 " + CHR(10) //Caracter especial para remover do XML
    cTexto += "002.0   MAX MIGUEL         145980   17/02/23 " + CHR(10) //Observações dos pedidos repetidos
	cTexto += "001.0   MAX MIGUEL         138674   28/10/22 " + CHR(10) //Ajuste XML campo observação
	@ 10,70 SAY oSay PROMPT "GTOMS003" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
		
	ACTIVATE MSDIALOG oDlg CENTERED
Return .T.
