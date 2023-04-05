#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'


/*/{Protheus.doc} GTFAT020
   Gerar de forma automatica o valor do Peso Bruto no Pedido de Venda
   através da rotina - Gerenciamento de Movimentação de Veiculo.
   @type  Function
   @author FABIANE GORRI 
   @since 25/10/2021
/*/

User Function GTFAT020(oModel)

	Local aAreaAtu 	:= getarea()
	Local aValP 	:= {}
	Local aPedDes   := {}
	Local cPed		:= " "
	Local nI		:= 0

	cContrl := Alltrim(oModel:GetValue("MASTER","PC2_CTRLE"))
	cPlaca1 := Alltrim(oModel:GetValue("MASTER","PC2_PLACA"))

	if select("qSQL") > 0
		qSQL->(dbCloseArea())
	endIf

	// BUSCAR OS PEDIDOS MAES E FILHOS
	BEGINSQL ALIAS "qSQL"
		SELECT DISTINCT PAZ.PAZ_PEDIDO, PAZ.PAZ_FILIAL, PAZ.PAZ_PEDDES, PAZ.PAZ_FILDES
		FROM %table:PC2% PC2
			JOIN %table:DK1% DK1 ON DK1.DK1_FILPED = PC2.PC2_FILIAL AND DK1.DK1_VIAGID = PC2.PC2_VIAGEM AND DK1.%notDel%
			JOIN %table:SC6% SC6 ON SC6.C6_FILIAL = PC2.PC2_FILIAL AND SC6.C6_NUM = DK1.DK1_PEDIDO AND DK1.DK1_PRODUT = SC6.C6_PRODUTO AND DK1.DK1_ITEMPE = SC6.C6_ITEM AND SC6.%notDel%
			JOIN %table:PAZ% PAZ ON PAZ.PAZ_FILIAL = PC2.PC2_FILIAL AND PAZ.PAZ_PEDIDO = SC6.C6_NUM AND PAZ.PAZ_PRODUT = SC6.C6_PRODUTO AND PAZ.PAZ_ITEORI = SC6.C6_ITEM AND PAZ.%notDel%
		WHERE PC2.%notDel%
		AND PC2.PC2_CTRLE = %exp:cContrl%
		AND PC2.PC2_PLACA = %exp:cPlaca1%
			UNION ALL 
		SELECT DISTINCT PAZ.PAZ_PEDIDO, PAZ.PAZ_FILIAL, PAZ.PAZ_PEDDES, PAZ.PAZ_FILDES
		FROM %table:PC2% PC2
			JOIN %table:DK1% DK1 ON DK1.DK1_FILPED = PC2.PC2_FILIAL AND DK1.DK1_VIAGID = PC2.PC2_VIAGEM AND DK1.%notDel%
			JOIN %table:SC6% SC6 ON SC6.C6_FILIAL = PC2.PC2_FILIAL AND SC6.C6_NUM = DK1.DK1_PEDIDO AND DK1.DK1_PRODUT = SC6.C6_PRODUTO AND DK1.DK1_ITEMPE = SC6.C6_ITEM AND SC6.%notDel%
			JOIN %table:PAZ% PAZ ON PAZ.PAZ_FILDES = PC2.PC2_FILIAL AND PAZ.PAZ_PEDDES = SC6.C6_NUM AND PAZ.PAZ_PRODUT = SC6.C6_PRODUTO AND PAZ.PAZ_ITEDES = SC6.C6_ITEM AND PAZ.%notDel%
		WHERE PC2.%notDel%
		AND PC2.PC2_CTRLE = %exp:cContrl%
		AND PC2.PC2_PLACA = %exp:cPlaca1%		

	ENDSQL

	dbSelectArea("qSQL")
	qSQL->(dbGoTop())

	If !(qSQL->(eof()))

		While !(qSQL->(eof()))

			nPos := Ascan(aPedDes, {|x| x[3] == qSQL->PAZ_FILDES .AND.  x[4] == qSQL->PAZ_PEDDES  }) // BUSCA FILIAL FILHO E PEDIDO FILHO 
			If nPos == 0
				Aadd( aPedDes, { qSQL->PAZ_FILIAL ;
					, qSQL->PAZ_PEDIDO ;
					, qSQL->PAZ_FILDES ;
					, qSQL->PAZ_PEDDES })
			EndIf

			qSQL->(dbSkip())
		EndDo

		IF Len(aPedDes) == 1
			cPedF  := aPedDes[1][1]
			cPed   := aPedDes[1][2]
			cFilhF := aPedDes[1][3]
			cFilhP := aPedDes[1][4]
		ELSE
			For nI := 1 To Len(aPedDes) //  FORMATA PARA FAZER A BUSCA NO SELECT (IN)
				If Empty(cPed)
					cPedF   := 	aPedDes[nI][1]
					cPed    := 	aPedDes[nI][2]
					cFilhF 	:=  aPedDes[nI][3] + "'" + ","
					cFilhP 	:=  aPedDes[nI][4] + "'" + ","
				ElseIf nI <>  Len(aPedDes)
					cFilhF +=  "'" + aPedDes[nI][3] + "'" + ","
					cFilhP +=  "'" + aPedDes[nI][4] + "'" + ","
				ELSE
					cFilhF +=  "'" + aPedDes[nI][3]
					cFilhP +=  "'" + aPedDes[nI][4]
				EndIf
			Next nI
		EndIf

		if select("qOra") > 0
			qOra->(dbCloseArea())
		endIf

		// BUSCAR AS PESAGENS DOS RESPECTIVOS PEDIDOS MAES E FILHOS
		BEGINSQL ALIAS "qOra"
			SELECT DISTINCT PC2.PC2_FILIAL,PC2.PC2_PLACA, PC2.PC2_VIAGEM, PC2.PC2_PESO1, PC2.PC2_PESO2, PAZ.PAZ_PEDIDO, PAZ.PAZ_FILIAL 
			FROM %table:PC2% PC2
				JOIN %table:DK1% DK1 ON DK1.DK1_FILPED = PC2.PC2_FILIAL AND DK1.DK1_VIAGID = PC2.PC2_VIAGEM AND DK1.%notDel%
				JOIN %table:SC6% SC6 ON SC6.C6_FILIAL = PC2.PC2_FILIAL AND SC6.C6_NUM = DK1.DK1_PEDIDO AND DK1.DK1_PRODUT = SC6.C6_PRODUTO AND DK1.DK1_ITEMPE = SC6.C6_ITEM AND SC6.%notDel%
				JOIN %table:PAZ% PAZ ON PAZ.PAZ_FILDES = PC2.PC2_FILIAL AND PAZ.PAZ_PEDDES = SC6.C6_NUM AND PAZ.PAZ_PRODUT = SC6.C6_PRODUTO AND PAZ.PAZ_ITEDES = SC6.C6_ITEM AND PAZ.%notDel%
			WHERE PC2.%notDel%
			AND PAZ.PAZ_PEDDES IN ( %exp:cFilhP% )
			AND PAZ.PAZ_FILDES IN ( %exp:cFilhF% )
			AND PAZ.PAZ_PEDIDO = %exp:cPed%
			AND PAZ.PAZ_FILIAL = %exp:cPedF%
			AND PC2.PC2_DATCAN = ' ' 
				UNION ALL
			SELECT DISTINCT PC2.PC2_FILIAL,PC2.PC2_PLACA, PC2.PC2_VIAGEM, PC2.PC2_PESO1, PC2.PC2_PESO2, PAZ.PAZ_PEDIDO, PAZ.PAZ_FILIAL 
			FROM %table:PC2% PC2
				JOIN %table:DK1%  DK1 ON DK1.DK1_FILPED = PC2.PC2_FILIAL AND DK1.DK1_VIAGID = PC2.PC2_VIAGEM AND DK1.%notDel%
				JOIN %table:SC6% SC6 ON SC6.C6_FILIAL = PC2.PC2_FILIAL AND SC6.C6_NUM = DK1.DK1_PEDIDO AND DK1.DK1_PRODUT = SC6.C6_PRODUTO AND DK1.DK1_ITEMPE = SC6.C6_ITEM AND SC6.%notDel%
				JOIN %table:PAZ% PAZ ON PAZ.PAZ_FILIAL = PC2.PC2_FILIAL AND PAZ.PAZ_PEDIDO = SC6.C6_NUM AND PAZ.PAZ_PRODUT = SC6.C6_PRODUTO AND PAZ.PAZ_ITEORI = SC6.C6_ITEM AND PAZ.%notDel%
			WHERE PC2.%notDel%
			AND PAZ.PAZ_PEDIDO = %exp:cPed%
			AND PAZ.PAZ_FILIAL = %exp:cPedF%
			AND PC2.PC2_DATCAN = ' ' 
			ORDER BY PC2_PESO1
		ENDSQL

		dbSelectArea("qOra")
		qOra->(dbGoTop())

		cChave :=  qOra->PAZ_FILIAL + qOra->PAZ_PEDIDO

		WHILE !(qOra->(eof()))

			Aadd(aValP, {qOra->PC2_FILIAL ;
				, qOra->PC2_PESO1 ;
				, PC2_PESO2 })

			qOra->(dbSkip())
		ENDDO

		If LEN(aValP) == 1 
			nPesBr := aValP[1][3] - aValP[1][2]  
		Else 
			FOR nI := 1 TO LEN(aValP)
				If nI == 1
					nPesFi := aValP[nI][2] // PRIMEIRA PESAGEM 
				ElseIf nI == LEN(aValP)
					nPesMa := aValP[nI][3] // SEGUNDA PESAGEM 
					nPesBr := nPesMa - nPesFi
				EndIf

			NEXT nI
		EndIf
		// GRAVAR NO PEDIDO DE VENDA MAE O VALOR DO PESO BRUTO
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1))
		IF SC5->( Dbseek(cChave) )
			RecLock("SC5", .F.)
			SC5->C5_PBRUTO := nPesBr
			SC5->(MsUnlock())
		ENDIF

		qOra->(dbCloseArea())
		SC5->(dbCloseArea())

	EndIf

	qSQL->(dbCloseArea())
	RestArea(aAreaAtu)

Return
