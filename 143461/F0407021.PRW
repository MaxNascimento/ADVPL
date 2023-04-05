#INCLUDE 'Totvs.CH'
#INCLUDE "FWMVCDEF.CH"

static __nLogProc 	:= 0
static lLog			:= .F.

/*/{Protheus.doc} F0407021
//Rotina de Calculo de frete autonomo.

Baseado no GFEX011.prw - função GFEX011SIM()

@author    Ronaldo Dantas
@since     08/07/20
@project   0000032563
@history 
/*/
User Function F0407021(lSC5Grv, lFatDAK) //- Ricardo

	//Declarando variáveis
	Local aArea 		:= GetArea()
	Local aAreaSC6		:= SC6->( GetArea() )
	Local aRetPed		:= {}

	Local oModelSim  	:= FWLoadModel("GFEX010") 
	Local oModelNeg  	:= oModelSim:GetModel("GFEX010_01") // oModel de negociacao
	Local oModelAgr  	:= oModelSim:GetModel("DETAIL_01")  // oModel do grid "Agrupadores"
	Local oModelDC   	:= oModelSim:GetModel("DETAIL_02")  // oModel do grid "Doc Carga"
	Local oModelIt   	:= oModelSim:GetModel("DETAIL_03")  // oModel do grid "Item Carga"
	Local oModelTr   	:= oModelSim:GetModel("DETAIL_04")  // oModel do grid "Trechos"
	Local oModelInt  	:= oModelSim:GetModel("SIMULA")     // oModel do field que dispara a simulação
	Local oModelCal1 	:= oModelSim:GetModel("DETAIL_05")  // oModel do calculo do frete
	Local oModelCal2 	:= oModelSim:GetModel("DETAIL_06")
	              
	Local cCdClFr		:= SuperGetMv("MV_CDCLFR", ,"") // Classificação de Frete no GFE //- Ricardo
	Local cTpOp			:= SuperGetMv("MV_CDTPOP", ,"") // Tipo de Operação de Frete no GFE //- Ricardo
	Local cCdTpDc		:= ""
	Local cCdRem		:= ""
	Local cCdDest		:= ""
	Local cCnpj			:= ""

	Local nCont      	:= 0
	Local nLenAcols		:= 0
	Local nItem			:= 0
	Local nX			:= 0                               
	Local nVlrFrt		:= 0
	Local nAltura		:= 0
	Local nVolume		:= 0
	Local nRadio		:= 0
	Local cCdTransp		:= ""

    Local cTransp  := ""
    Local cCliPed  := ""
    Local cLojCli  := ""
    Local cTipo    := ""
	Local nPProd   := 0
	Local nPQtdVen := 0
	Local nPValor  := 0
	Local cCdTpVc  := ""
	Local cVeiculo := ""
	Local cCdTrp   := ""
	

	Local cCidaRem	:= ""//Cidade do Remetente 	//- Ricardo
	Local cCidaDes	:= ""//Cidade do Destinário	//- Ricardo

	local aEmpInfo  := FWSM0Util():GetSM0Data( cEmpAnt ,cFilAnt , { "M0_CGC" } )
	local cCgcEmp   := iif(len(aEmpInfo)>0, alltrim(aEmpInfo[1][2]), "")
	
    Default lSC5Grv := .T.
	Default lFatDAK	:= .F. //- Ricardo
	Local lMontDAK	:= (FunName() == "OMSA200")

    If lSC5Grv
        cNumPed  := SC5->C5_NUM
        cTransp  := SC5->C5_TRANSP
        cCliPed  := SC5->C5_CLIENT
        cLojCli  := SC5->C5_LOJAENT
        cTipo    := SC5->C5_TIPO
		cVeiculo := SC5->C5_VEICULO

		IF lFatDAK //- Ricardo
			cTransp		:= Posicione("DAK",1,xFilial("DAK") + SC9->C9_CARGA , "DAK_TRANSP") //- Ricardo
			cVeiculo	:= Posicione("DAK",1,xFilial("DAK") + SC9->C9_CARGA , "DAK_CAMINH") //- Ricardo
			cCdClFr		:= Posicione("DAK",1,xFilial("DAK") + SC9->C9_CARGA , "DAK_CDCLFR") //- Ricardo
			cTpOp		:= Posicione("DAK",1,xFilial("DAK") + SC9->C9_CARGA , "DAK_CDTPOP") //- Ricardo
		elseif lMontDAK
			cTransp		:= cCarTran
			cVeiculo	:= cCarVei
			cCdClFr		:= cCarClFt
			cTpOp		:= cCarTpOp
		EndIF
    Else
        cNumPed  := M->C5_NUM
        cTransp  := M->C5_TRANSP
        cCliPed  := M->C5_CLIENT
        cLojCli  := M->C5_LOJAENT
        cTipo    := M->C5_TIPO
		cVeiculo := M->C5_VEICULO
	    nPProd   := ASCAN(AHEADER, {|X| ALLTRIM(X[2]) == "C6_PRODUTO"})
	    nPQtdVen := ASCAN(AHEADER, {|X| ALLTRIM(X[2]) == "C6_QTDVEN"})
	    nPValor  := ASCAN(AHEADER, {|X| ALLTRIM(X[2]) == "C6_VALOR"})
    EndIf

	If !Empty(cTransp)

		If lSC5Grv
			SC6->(dbSetOrder(1))
			If SC6->( DbSeek(xFilial("SC6") + SC5->C5_NUM ) ) //C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
				While SC6->(!Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == (SC5->C5_FILIAL+SC5->C5_NUM)
					AADD (aRetPed, {SC6->C6_PRODUTO,SC6->C6_QTDVEN,SC6->C6_VALOR} )
					SC6->(dbSkip())
				EndDo
			EndIf
		Else
        	For nX := 1 to len(aCols)
				AADD (aRetPed, {aCols[nX][nPProd],aCols[nX][nPQtdVen],aCols[nX][nPValor]} )
			Next nX
		Endif

		nRadio		:= 2  // -- 1=Considera Tab.Frete em Negociacao; 2=Considera apenas Tab.Frete Aprovadas
		nLenAcols	:= Len(aRetPed) //Itens do pedido

		SA1->(dbSetOrder(1))
		SA1->(dbSeek(xFilial("SA1")+cCliPed+cLojCli)) 
		If !cTipo $ "DB"
			cCnpj :=  SA1->A1_CGC
		Else
			cCnpj :=  Posicione("SA2",1,FWxFilial("SA2")+cCliPed+cLojCli,"A2_CGC")
		EndIf	

		cCdTpDc := Posicione("SX5",1,xFilial("SX5")+"MQ"+AllTrim(cTipo)+"S","X5_DESCRI")

		If Empty(cCdTpDc)
			cCdTpDc := Posicione("SX5",1,xFilial("SX5")+"MQ"+AllTrim(cTipo),"X5_DESCRI")
		EndIf

		cCdTpDc := PadR(cCdTpDc,TamSx3("GW1_CDTPDC")[1])		

		cCdRem 	:= IIF(MTA410ChkEmit(cCgcEmp),cCgcEmp, MTA410RetEmit(xFilial("SC5")) ) 
		cCdDest := IIF(MTA410ChkEmit(cCnpj),cCnpj, OMSM011COD(cCliPed,cLojCli,1,,) )
			
		cCidaRem := Posicione("GU3",1,xFilial("GU3") + cCdRem	,"GU3_NRCID")//Cidade do Remetente 	//- Ricardo
		cCidaDes := Posicione("GU3",1,xFilial("GU3") + cCdDest	,"GU3_NRCID")//Cidade do Destinário	//- Ricardo

		//simula como inclusão
		oModelSim:SetOperation(3) 
		oModelSim:Activate() 			
		oModelNeg:LoadValue('CONSNEG' ,AllTrim(Str(nRadio))) // 1=Considera Tab.Frete em Negociacao; 2=Considera apenas Tab.Frete Aprovadas
		
		//Agrupadores - N? obrigatorio
		oModelAgr:LoadValue('GWN_CDCLFR',cCdClFr)  //classifica?o de frete                                 
		oModelAgr:LoadValue('GWN_CDTPOP',cTpOp)    //tipo da opera?o
		oModelAgr:LoadValue('GWN_DOC'   ,"ROMANEIO"     )           

		//Documento de Carga
		oModelDC:LoadValue('GW1_EMISDC', cCgcEmp) 	//codigo do emitente - chave
		oModelDC:LoadValue('GW1_NRDC'  , cNumPed  ) 	//numero da nota - chave
		oModelDC:LoadValue('GW1_CDTPDC', cCdTpDc) 		// tipo do documento - chave
		oModelDC:LoadValue('GW1_CDREM' , cCdRem)  	//remetente
		oModelDC:LoadValue('GW1_CDDEST', cCdDest)   //destinatario
		oModelDC:LoadValue('GW1_TPFRET', "1")
		oModelDC:LoadValue('GW1_ICMSDC', "2")
		oModelDC:LoadValue('GW1_USO'   , "1")
		oModelDC:LoadValue('GW1_QTUNI' , 1)   

		//Trechos
		oModelTr:LoadValue('GWU_EMISDC' ,cCgcEmp)		//codigo do emitente - chave
		oModelTr:LoadValue('GWU_NRDC'   ,cNumPed  ) 	//numero da nota - chave
		oModelTr:LoadValue('GWU_CDTPDC' ,cCdTpDc)			// tipo do documento - chave
		oModelTr:LoadValue('GWU_SEQ'    ,"01"   )    		//sequencia - chave
		oModelTr:LoadValue('GWU_NRCIDO' ,cCidaRem)   // codigo da cidade Origem para o calculo //- Ricardo
		oModelTr:LoadValue('GWU_NRCIDD' ,cCidaDes)   // codigo da cidade Destino para o calculo //- Ricardo
		//oModelTr:LoadValue('GWU_NRCIDD' ,AllTrim(TMS120CdUf(SA1->A1_EST, "1") + SA1->A1_COD_MUN))   // codigo da cidade Destino para o calculo //- Ricardo
		//oModelTr:LoadValue('GWU_CEPO', POSICIONE("GU3",1,xFilial("GU3")+cCdRem,"GU3_CEP")) //- Ricardo
		//oModelTr:LoadValue('GWU_CEPD', POSICIONE("GU3",1,xFilial("GU3")+cCdDest,"GU3_CEP")) //- Ricardo

		If !Empty(cVeiculo)
			cCdTpVc := POSICIONE("DA3",1,xFilial("DA3")+cVeiculo,"DA3_TIPVEI")
			If !Empty(cCdTpVc)
				oModelTr:LoadValue('GWU_CDTPVC', cCdTpVc) // adiciona o tipo do veículo para cálculo do frete
			Endif	
		Endif

		cCdTrp := POSICIONE("GU3",13,xFilial("GU3")+cTransp,"GU3_CDEMIT")
		If !Empty(cCdTrp)
			oModelTr:LoadValue('GWU_CDTRP', cCdTrp) // adiciona o transportador 
		EndIf

		//Itens	do documento							
		For nX:= 1 To nLenACols			
			nItem += 1
			nAltura := Posicione("SB5",1,xFilial("SB5")+aRetPed[nX][1],"B5_ALTURA")
			nVolume := (nAltura * SB5->B5_LARG * SB5->B5_COMPR) * aRetPed[nX][2]			
			SB1->(DbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+aRetPed[nX][1])) //B1_FILIAL+B1_COD

			//--VERIFICAR QUESTAO DOS PRODUTOS
			oModelIt:LoadValue('GW8_EMISDC',cCgcEmp)	//codigo do emitente - chave
			oModelIt:LoadValue('GW8_NRDC'  ,cNumPed  ) 	//numero do documento - chave
			oModelIt:LoadValue('GW8_CDTPDC',cCdTpDc) 		// tipo do documento - chave
			oModelIt:LoadValue('GW8_ITEM'  , "ITEM"+ PADL((nItem),3,"0")  )  //codigo do item    
			oModelIt:LoadValue('GW8_DSITEM', "ITEM GENERICO  "	+ PADL((nItem),3,"0"))  //descricao do item 
			oModelIt:LoadValue('GW8_CDCLFR',cCdClFr)  //classificacao de frete
			oModelIt:LoadValue('GW8_VOLUME',nVolume)  //Volume
			oModelIt:LoadValue('GW8_PESOR' ,aRetPed[nX][2] * SB1->B1_PESBRU ) 	//peso real
			oModelIt:LoadValue('GW8_VALOR' ,aRetPed[nX][3] ) //valor do item
			oModelIt:LoadValue('GW8_QTDE'  ,aRetPed[nX][2] ) //Quantidade por item
			oModelIt:LoadValue('GW8_TRIBP' ,"1" )
			oModelIt:AddLine(.T.)

		Next nX   

		// Não mostra a tela de Log do processamento
		GFEX010Slg(__nLogProc)

		If !lLog .And. __nLogProc == 0

			// Dispara a simulacao
			oModelInt:SetValue("INTEGRA" ,"A") 	
		
			//Verifica se tem linhas no modelo do calculo, se nao tem linhas significa que o calculo falhou e retorna zero
			If oModelCal1:GetQtdLine() > 1 .Or. !Empty( oModelCal1:GetValue('C1_NRCALC'  ,1) )
				//Percorre o grid, cada linha corresponde a um calculo diferente
				For nCont := 1 to oModelCal1:GetQtdLine()
					oModelCal1:GoLine( nCont )       
					
					cCdTransp := POSICIONE("GU3",1,xFilial("GU3")+oModelCal2:GetValue('C2_CDEMIT'  ,1 ),"GU3_CDTERP")
					If cTransp == cCdTransp
						nVlrFrt	  := oModelCal1:GetValue('C1_VALFRT'  ,nCont )       
						EXIT
					Endif	

				Next nCont    
			Else
				//Valor zerado caso ocorrer erro	
				cCdTransp := POSICIONE("GU3",1,xFilial("GU3")+oModelCal2:GetValue('C2_CDEMIT'  ,1 ),"GU3_CDTERP")
				If cTransp == cCdTransp
					nVlrFrt	:= oModelCal1:GetValue('C1_VALFRT' ,1 ) 
				Endif	
			EndIf
		EndIf
	EndIf

	RestArea(aArea)	
	RestArea(aAreaSC6)		

	aSize(aEmpInfo,0)
Return ( nVlrFrt ) 

/*/{Protheus.doc} MTA410RetEmit(cFil)
//Rotina que verifica o codigo do emissor                                               
| Autor: Ronaldo Dantas                                               
| Data:  09/07/2020                                                   
| Desc:  Função de verificação do codigo emissor                             
| Obs.:                                                             
/*/
Static Function MTA410RetEmit(cFil)

Local aAreaGW0
Local aArea := GetArea()
Local cCodGFE := ""

aAreaGW0 := GW0->( GetArea() )
dbSelectArea("GW0")
GW0->( dbSetOrder(1) )
GW0->( DbSeek( Space( TamSx3("F2_FILIAL")[1] )+PadR( "FILIALEMIT",TamSx3("GW0_TABELA")[1] )+PadR( cFil,TamSx3("GW0_CHAVE")[1] ) ) ) //GW0_FILIAL+GW0_FILEMIT+GW0_CHAVE
If !GW0->( EOF() ) .And. GW0->GW0_FILIAL == Space( TamSx3("F2_FILIAL")[1] );
					  .And. GW0->GW0_TABELA == PadR( "FILIALEMIT",TamSx3("GW0_TABELA")[1] );
					  .And. GW0->GW0_CHAVE == PadR( cFil,TamSx3("GW0_CHAVE")[1] )

	cCodGFE := PadR( GW0->GW0_CHAR01,TamSx3("GW1_EMISDC")[1] )
EndIf
RestArea( aAreaGW0 )

RestArea( aArea )
		
Return cCodGFE
