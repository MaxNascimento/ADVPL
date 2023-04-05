#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} G0108656
//TODO Descrição auto-gerada.
@author Gerson Luz
@since 21/02/2020
@version 1.0
@type function
/*/
User Function G0108656()

Local lRet := .t.
Local oButton1
Local oPanel1
Local oSay1
Local oSay2
Local oSay3
Local oSay4
Local oSay5

Local oGetBomba 	 
Local oGetDescF 	 
Local oGetFrota 	 	
Local oGetPosto 	 
Local oGetTanque 	 
Local oGetFilial 	 
Local oGetCnpj 	
Local oGetDescPo  
Local cCombReq 		:= ""
Local cCombFrt 		:= ""
Local cMotorista	:= ""

Private cGetBomba 	:= Space(TAMSX3("TQN_BOMBA")[1])
Private cGetDescF 	:= Space(60)
Private cGetFrota 	:= Space(TAMSX3("TQN_FROTA")[1])
Private cGetPosto 	:= Space(TAMSX3("TQN_POSTO")[1])
Private cGetTanque 	:= Space(TAMSX3("TQN_TANQUE")[1])
Private cCnpjPosto 	:= Space(TAMSX3("TQN_CNPJ")[1])

Private cGetFilial 	:= Space(2)
Private cGetCnpj 	:= Space(12)
Private cGetDescPO  := Space(12)
Private cFrota655	:= Z23->Z23_FROTA
Private cPlaca655 	:= Z23->Z23_PLACA
Private cRec		:= ""
Private dDatAb655 := Z23->Z23_DATINC
Private	cHorAb655 := time() 
Private	cNotaF655 := Z23->Z23_NFISCA
Private	cPosto655 := cGetPosto
Private	cLojaP655 := cGetFilial
Private	cCombu655 := Z23->Z23_CODCOM 
Private	cBomba655 := cGetBomba
Private	cTanqu655 := cGetTanque
Private cFilBemST9 := ""

Private cVer17801	:='001'			//controle de versão
Private cDt17801	:='03/03/2021'	//Data Manutenção	
	
	If FindFunction("U_G0108V")
		SetKey(K_CTRL_F12, {||U_G0108V()})
	Else
		SetKey(K_CTRL_F12, Nil)
	EndIf



Static oDlg

//POSICIONA NA TABELA DE COMBUSTIVEL E PREENCHE VARIÁVEIS PARA VALIDAÇÃO DO LANÇAMENTO
	dbSelectArea("TQM")	
	dbSetOrder(1)
	dbSeek(xFilial("TQM")+cCombu655)
	
	cRec	  		:= AllTrim(Str(RecNo()))
   	cFrota655 		:= Z23->Z23_PLACA
   	cTpFrota		:= Z23->Z23_TIPABA
   	cMotorista		:= Z23->Z23_MOTOR
   	If Z23->Z23_STATUS <> "U" .AND. (Z23->Z23_TPABAS <> "I" .AND. Z23->Z23_TIPABA <> "T")
 		Help(,,"[G0108656]Erro Bx Estoque",,"Status não permitido a Bx de Estoque" , 1, 0,,,,,,{"Não é permitido baixa de estoque para Status diferente de Usado."})
   		lRet := .F.
   		Return lRet  		
   	End If
   	IF cTpFrota == "O" // -> Abastecimento Externo -> Movimenta apenas financeiro
   		Help(,,"[G0108656]Erro Bx Estoque",,"Tipo de Frota: Outros" , 1, 0,,,,,,{"Não é permitido baixa de estoque para Tipo de Frota - Outros."})
   		lRet := .F.
   		Return lRet
   	endif
   	
   	dbSelectArea("DA4")
   	dbSetOrder(1)
   	If DbSeek(xFilial()+cMotorista)
   		if DA4->DA4_BLQMOT == "S"
   			Help(,,"[G0108656]Erro Bx Estoque",,"O cadastro de motorista está bloqueado" , 1, 0,,,,,,{"Desbloqueie o Motorista no cadastro."})
   			lRet := .F.
   			Return lRet
   		ENDIF
   	endif
    DbSelectArea("ST9")
   	DbSetOrder(14)
   	if DbSeek(Z23->Z23_PLACA)
   		cGetFrota 	:= ST9->T9_CODBEM
   		cFilbem  	:= ST9->T9_FILIAL
		cFilBemST9	:= ST9->T9_FILIAL
   		cCCusto  	:= ST9->T9_CCUSTO
   		cCentrab 	:= ST9->T9_CENTRAB
   		dbSelectArea("TT8")
   		dbSetOrder(1)
   		if dbseek(xFilial("TT8")+cGetFrota)
   			cCombReq := Z23->Z23_CODCOM
   			cCombFrt := TT8->TT8_CODCOM
   			if AllTrim(Z23->Z23_CODCOM) <> AllTrim(TT8->TT8_CODCOM)
   				Help(,,"[G0108656]Erro Bx Estoque",,"Combustivel incompatível com o tanque bem" , 1, 0,,,,,,{"Verificar o combustivel cadastrado no bem: "+cCombFrt+ " e comparar com o colocado na requisição de abastecimento: " +cCombReq })
   				lRet := .F.
   				Return lRet
   			ENDIF
   		else
   			Help(,,"[G0108656]Erro Bx Estoque",,"Combustivel incompatível com o tanque bem", 1, 0,,,,,,{"Verificar o combustivel cadastrado no bem e comparar com o colocado na requisição de abastecimento."})
   			lRet := .F.
   			Return lRet
   		endif
   	Else 
   	   	Help(,,"[G0108656]Erro Bx Estoque",,"Placa do veiculo não cadastrada", 1, 0,,,,,,{"Cadastrar o veiculo no cadastro de bens."})
		lRet := .F.
		Return lRet
   	endif
	//MOSTRA A TELA SOMENTE PARA ABASTECIMENTO INTERNO
	if Z23->Z23_TPABAS == "I"

		DEFINE MSDIALOG oDlg TITLE "Dados Adicionais" FROM 000, 000  TO 200, 510 COLORS 0, 16777215 	PIXEL

    	@ 001, 001 MSPANEL oPanel1 SIZE 253, 083 OF oDlg COLORS 0, 16777215 RAISED
    	
    	@ 005, 003 SAY   oSay1      PROMPT  "Cod Frota:"  SIZE 028, 010 OF oPanel1 	COLORS 0, 16777215 		  	PIXEL
    	@ 015, 001 MSGET oGetFrota  VAR 	cGetFrota     SIZE 060, 010 OF oPanel1	COLORS 0, 16777215 		  	PIXEL F3 "ST9"  VALID  fDescFrt()                                                                                                                
    	@ 015, 070 MSGET oGetDescF  VAR     cGetDescF     SIZE 174, 010 OF oPanel1	COLORS 0, 16777215 READONLY PIXEL
      	@ 030, 003 SAY   oSay2      PROMPT  "Cod Posto:"  SIZE 063, 010 OF oPanel1 	COLORS 0, 16777215 			PIXEL
    	@ 040, 003 MSGET oGetPosto  VAR     cGetPosto     SIZE 060, 010 OF oPanel1 	COLORS 0, 16777215 			PIXEL F3 "NGK" VALID fDescPosto()  
    	@ 040, 070 MSGET oGetFilial VAR     cGetFilial    SIZE 012, 010 OF oPanel1 	COLORS 0, 16777215 READONLY PIXEL
    	@ 040, 090 MSGET oGetDescPo VAR     cGetDescPO    SIZE 154, 010 OF oPanel1 	COLORS 0, 16777215 READONLY PIXEL
    	
    	
    	@ 055, 003 SAY   oSay3      PROMPT "Tanque:"      SIZE 025, 010 OF oPanel1 	COLORS 0, 16777215          PIXEL
    	@ 065, 003 MSGET oGetTanque VAR     cGetTanque    SIZE 060, 010 OF oPanel1 	COLORS 0, 16777215          PIXEL F3 "FSTQI" VALID ExistCpo('TQI',cGetPosto+cGetFilial+cGetTanque) .AND. fTanq()                                                  
    	@ 055, 070 SAY   oSay4      PROMPT "Bomba:"       SIZE 025, 010 OF oPanel1 	COLORS 0, 16777215          PIXEL
    	@ 065, 070 MSGET oGetBomba  VAR     cGetBomba     SIZE 012, 010 OF oPanel1 	COLORS 0, 16777215          PIXEL F3 "FSTQJ" VALID EXISTCPO('TQJ',cGetPosto+cGetFilial+cGetTanque+cGetBomba)  .AND. fTanqBomba()                                                  
    	@ 055, 098 SAY   oSay5      PROMPT "CNPJ:"        SIZE 020, 010 OF oPanel1 	COLORS 0, 16777215          PIXEL
    	@ 065, 098 MSGET oGetCnpj   VAR    cGetCnpj       SIZE 146, 010 OF oPanel1 	COLORS 0, 16777215 READONLY PIXEL
    	
    	@ 085, 170 BUTTON oButton1 PROMPT "&Confirmar" SIZE 037, 012 OF oDlg PIXEL Action(fProcRot())
    	@ 085, 218 BUTTON oButton1 PROMPT "C&ancelar"  SIZE 037, 012 OF oDlg PIXEL Action(oDlg:end())
    	
    	ACTIVATE MSDIALOG oDlg CENTERED    
	Else
		Help(,,"[G0108656]Erro Bx Estoque",,"Somente Tipo de Abastecimento Interno", 1, 0,,,,,,{"Tipo de Abastecimento Externo, não Baixa estoque"})
		lRet := .F.
	endif
	
Return lRet

// VALIDA AS INFORMAÇÕES DIGITADAS NA TELA E CONFIRMA O LANÇAMENTO PELA ROTINA DE EXECAUTO
Static Function fProcRot()

Local lRet := .t.
		 //pre validações
		 //somente para fechados
		 If AllTrim(cGetFrota) == ""
		 	Help(,,"[G0108656]Erro Bx Estoque",,"Campo: Frota, não preechido", 1, 0,,,,,,{"Preencha do campo Frota"})
		 	lRet := .F.	
		 endif
		 If AllTrim(cGetPosto) == ""
		 	Help(,,"[G0108656]Erro Bx Estoque",,"Campo: Posto, não preechido", 1, 0,,,,,,{"Preencha o campo Posto."})
		 	lRet := .F.	
		 endif
		If !IsBlind()
			if msgyesno("Deseja fazer a baixa do estoque?","Atenção")
				Processa( {||fconfirma() }, "Processando aguarde...")
			else
				oDlg:End()
			EndIf
		else
				Processa( {||fconfirma() }, "Processando aguarde...")
		endif


Return lRet

//Monta os dados para o execauto e processa a entrada de dados.
Static Function fConfirma()
	
	Local lRet := .T.
    Local aAbast := {}
   	local cMsgErro := ""
	local cLogPath := SuperGetMV("MV_LOGPATH",,"logs")  //Pasta para gravacao do log de erro pela funcao Mostraerro().  
	local cArqLog  := ""
    //somente para frota
    // Itens obrigatórios para inclusão do abastecimento para posto interno

 	aAbast := { {'TQN_PLACA', PadR( Z23->Z23_PLACA      	, TAMSX3("TQN_PLACA")[1] ) , Nil },;
                {'TQN_FROTA' , PadR( cGetFrota          	, TAMSX3("TQN_FROTA")[1] ) , Nil },;
                {'TQN_CNPJ'  , PadR( cGetCnpj 				, TAMSX3("TQN_CNPJ")[1] )  , Nil },;
                {'TQN_CODCOM', PadR( Z23->Z23_CODCOM        , TAMSX3("TQN_CODCOM")[1] ), Nil },;
                {'TQN_DTABAS', Z23->Z23_DATINC              , Nil },;
                {'TQN_HRABAS', time()                       , Nil },;
                {'TQN_TANQUE', PadR(cGetTanque      		, TAMSX3("TQN_TANQUE")[1] ), Nil },;
                {'TQN_BOMBA' , PadR( cGetBomba           	, TAMSX3("TQN_BOMBA")[1] ) , Nil },;
                {'TQN_QUANT' , Z23->Z23_QTDE                                            , Nil },;
                {'TQN_VALUNI', Z23->Z23_UNITA                                           , Nil },;
                {'TQN_VALTOT', Z23->Z23_TOTAL                                           , Nil },;
                {'TQN_HODOM' , Z23->Z23_HODOME                                          , Nil },;
                {'TQN_CODMOT', PadR( '000001'           	, TAMSX3("TQN_CODMOT")[1] ), Nil },;
                {'TQN_POSTO' , PadR(cGetPosto           	, TAMSX3("TQN_POSTO")[1] ) , Nil },;
                {'TQN_LOJA'  , PadR( cGetFilial             , TAMSX3("TQN_LOJA")[1] )  , Nil },;
                {'TQN_NOTFIS', PadR(Z23->Z23_NFISCA        	, TAMSX3("TQN_NOTFIS")[1] ), Nil }}					
 
        lMSHelpAuto := .T. // Não apresenta erro em tela
        lMSErroAuto := .F. // Caso a variável torne-se .T. apos MsExecAuto, apresenta erro em tela
     
        MSExecAuto( { | v, x, y | MNTA655( v, x, y ) }, , aAbast, 3,.T. )
        
		//------------------------------------------------------------------------------------------//
		// O execauto não separa o que é erro por validação ou por warning,                         //
		// desta forma se o registro não for icluído pelo execauto, foi deixado a                   // 
		// possibilidade do usuário confirmar assim mesmo.                                          //
		// Caso ele confirme mesmo com o erro/warning retornado pelo execauto, é feito um           //
		// lançamento manual, e também foi utilizado a rotina padrão do módulo manutenção de ativos //
		// para a baixa de estoque do produto - combustível que está na tabela TQI"                 //
		// -----------------------------------------------------------------------------------------//

		If lMsErroAuto
			//caso esteja processando por scheduller, não mostra mensagem nenhuma
        	If !IsBlind()
				MostraErro()
				if msgyesno("Confirma o movimento mesmo com o alerta anterior?","Atenção")
					Processa( {||fAbastec() }, "Processando aguarde...")
					oDlg:End()
			    endif
        	Else
				//Mensagem de erro do execauto
				cArqLog   := GetNextAlias()+".log"
				cMsgErro :=  MostraErro(cLogPath,cArqLog)
				
				//Apaga o arquivo de LOG.
				if file(cLogPath+"\"+cArqLog)
					FErase(cLogPath+"\"+cArqLog)
				endif
			
				fAbastec()
	        	oDlg:End()
	       	EndIf
        else
			//caso esteja processando por schedulle não mostra mensagem nenhuma
			fLogBX()
          	If !IsBlind()
          		Help(,,"[G0108656]Bx Estoque",,"Inclusão OK", 1, 0,,,,,,{"Bx. de Estoque Manual."})
				//Processa( {||fAbastec() }, "Processando aguarde...")
				oDlg:End()
        	Else
        		cError := "Inclusao OK"
        		ConOut( cError)
        		oDlg:End()
        	EndIf
        EndIf
  
return lRet


// função para validação do código do Bem
Static Function fDescFrt()

Local lRet := .T.
Local cBemAnt := ""
 	 
  	DbSelectArea("ST9")
   	DbSetOrder(14)
   	if DbSeek(Z23->Z23_PLACA)
   	   	cBemAnt   := ST9->T9_CODBEM
   	   	cGetDescF := ST9->T9_NOME
   	   	cFrota655 := ST9->T9_CODBEM
   	   	cPlaca655 := Z23->Z23_PLACA
   	endif
   	IF AllTrim(cBemAnt) == ""
   		Help(,,"[G0108656]Erro Alteração",,"Não pode ser feito a baixa de estoque,Código de Bem não cadastradado", 1, 0,,,,,,{"Cadastre o Bem no referido cadastro."})
   		lRet := .f.
   	endif
   	
Return lRet

//Função para preechimento da descrição do posto, tanque e bomba
Static Function fDescPosto()
Local lRet := .T.
Local cBemAnt := ""

Private cPosto  := ""
Private cLoja   := ""
Private cTanque := ""
Private cBomba  := ""
Private lBomba	:= ""
	 
	DbSelectArea("ST9")
	DbSetOrder(14)
   	if DbSeek(Z23->Z23_PLACA)
   	   	cBemAnt   := ST9->T9_CODBEM
   	   	cGetDescF := ST9->T9_NOME
   	   	cFrota655 := ST9->T9_CODBEM
   	   	cPlaca655 := Z23->Z23_PLACA
   	endif
   	cGetDescPO := TQF->TQF_NREDUZ
   	cGetCnpj	:= TQF->TQF_CNPJ
	if TQF->TQF_TIPPOS == "2"
		lBomba := .t.
	endif

   	IF AllTrim(cBemAnt) == ""
   		Help(,,"[G0108656]Erro Alteração",,"Não pode ser feito a baixa de estoque,Código de Frota não cadastradado.", 1, 0,,,,,,{"Verificar cadastro de Bens."})
   		lRet := .f.
   	endif

   	cPosto		:= TQF->TQF_CODIGO
	cLoja  		:= TQF->TQF_LOJA
	cTanque 	:= TQJ->TQJ_TANQUE
	cGetBomba 	:= TQJ->TQJ_BOMBA

Return lRet

// Função para carregar nas variáveis padrão as informações de posto, tanque, 
// combustivel
Static function fTanq()

Local lRet := .t.

	cPosto		:= TQI->TQI_CODPOS
	cLoja  		:= TQI->TQI_LOJA
	cTanque 	:= TQI->TQI_TANQUE
	cComb		:= TQI->TQI_PRODUT
	cGetBomba	:= TQJ->TQJ_BOMBA

Return lRet


// Função para carregar nas variáveis padrão as informações de posto, tanque, 
// combustivel
Static function fTanqBomba()

Local lRet := .t.

	cPosto		:= TQI->TQI_CODPOS
	cLoja  		:= TQI->TQI_LOJA
	cTanque 	:= TQI->TQI_TANQUE
	cGetBomba 	:= TQJ->TQJ_BOMBA

Return lRet

//Função para gravar na Z23 o estatus de BAIXA DE ESTOQUE
Static Function fLogBX()

Local lRet  := .T.

  	dbSelectArea("Z23")
    	RecLock("Z23",.F.)
    		Z23->Z23_USRTQN :=  Alltrim(UsrRetName(__CUSERID))
    		Z23->Z23_DATTQN := dDatabase
    		Z23->Z23_HORTQN := Time()
    		Z23->Z23_RECTQN := cRec
    		Z23->Z23_FROTA	:= cGetFrota
    		Z23->Z23_POSTO	:= cGetPosto
    		Z23->Z23_LOJA	:= cGetFilial
    		Z23->Z23_CNPJ	:= cGetCnpj
    		Z23->Z23_TANQUE	:= cGetTanque
        	Z23->Z23_BOMBA	:= cGetPosto
        	Z23->Z23_STATUS	:= "E"
        MsUnlock()

Return lRet


//Função para gravar manualmente os dados do Abastecimento, quando pela rotina de execauto,
//os dados não forem gravados.

Static Function fAbastec()

Local cAbaPlaca := PadR( Z23->Z23_PLACA      	, TAMSX3("TQN_PLACA")[1]  ) 
Local cAbaFrota	:= PadR( cGetFrota          	, TAMSX3("TQN_FROTA")[1]  )
Local cAbaCnpj	:= PadR( cGetCnpj 				, TAMSX3("TQN_CNPJ")[1]   ) 
Local cAbaComb	:= PadR( Z23->Z23_CODCOM        , TAMSX3("TQN_CODCOM")[1] )
Local cAbaDtAb	:= Z23->Z23_DATINC  
Local cAbaTime	:= Time()
Local cAbaTanq	:= PadR(cGetTanque      		, TAMSX3("TQN_TANQUE")[1] )
Local cAbaBomb	:= PadR( cGetBomba           	, TAMSX3("TQN_BOMBA")[1]  )
Local cAbaQtde	:= Z23->Z23_QTDE
Local cAbaVlUn	:= Z23->Z23_UNITA 
Local cAbaVlTo	:= Z23->Z23_TOTAL
Local cAbaHodo	:= Z23->Z23_HODOME
Local cAbaCodM	:= PadR( '000001'           	, TAMSX3("TQN_CODMOT")[1] )
Local cAbaPost	:= PadR(cGetPosto           	, TAMSX3("TQN_POSTO")[1]  )
Local cAbaLjPo	:= PadR( cGetFilial             , TAMSX3("TQN_LOJA")[1]   ) 
Local cAbaNfAb	:= PadR(Z23->Z23_NFISCA        	, TAMSX3("TQN_NOTFIS")[1] )
Local cAbaPrd	:=  TQI->TQI_PRODUT
Local cError 	:= ""

	begin transaction

	Reclock("TQN",.T.)
		TQN_FILIAL	:= xFilial("TQN")
		TQN_PLACA 	:= cAbaPlaca
     	TQN_FROTA	:= cAbaFrota 
        TQN_CNPJ	:= cAbaCnpj
		TQN_CODCOM	:= cAbaComb 
        TQN_DTABAS	:= cAbaDtAb 
        TQN_HRABAS	:= cAbaTime 
        TQN_TANQUE	:= cAbaTanq 
        TQN_BOMBA	:= cAbaBomb 
        TQN_QUANT	:= cAbaQtde  
        TQN_VALUNI	:= cAbaVlUn
        TQN_VALTOT	:= cAbaVlTo
        TQN_HODOM	:= cAbaHodo 
        TQN_CODMOT	:= cAbaCodM
        TQN_POSTO	:= cAbaPost 
        TQN_LOJA	:= cAbaLjPo 
        TQN_NOTFIS	:= cAbaNfAb 
	MsUnlock()
	//Execauto para baixa do estoque.


		cDocumSD3 := NextNumero("SD3",2,"D3_DOC",.T.)
		cNumSeqD  := u_MntMovEst1('RE0',cAbaTanq,cAbaPrd,cAbaQtde,cAbaDtAb,cCCusto,,cCCusto,,,, cAbaFrota, cFilBem )

		If Empty(cNumSeqD)
			DisarmTransaction()
		else
			fLogBX()
			If !IsBlind()
          		Help(,,"[G0108656]Bx Estoque",,"Inclusão OK", 1, 0,,,,,,{"Bx. de Estoque Manual."})
           		oDlg:End()
        	Else
        		cError := "Inclusao OK"
        		ConOut( cError)
        		oDlg:End()
        	EndIf
	EndIf
	
	End Transaction

Return .t.

User Function G0108V()

	Local cTexto := ""
	Local oDlg, oSay
	Local oFont:= TFont():New("Courier New",,-14,.T.)
	
	DEFINE MSDIALOG oDlg FROM 0,0 TO 600,400 TITLE "Controle de Versão" PIXEL
	
	cTexto := "VERSÃO  AUTOR              CHAMADO    DATA   " + CHR(10) 
	cTexto += "======  =================  =======  ======== " + CHR(10)
	cTexto += "001.O   Gerson Luz         GAP086   21/02/20 " + CHR(10) //Criação da rotina
	cTexto += "001.1   Gerson Luz         98473    22/02/21 " + CHR(10) //Ajuste na tela de digitação
	cTexto += "001.2   Gerson Luz         98473    03/03/21 " + CHR(10) //Revisado execauto que fazia a inclusão do registro
	
	@ 10,70 SAY oSay PROMPT "G0108656" SIZE 330,10 COLORS CLR_HBLUE FONT oFont OF oDlg PIXEL
	@ 20,10 SAY oSay PROMPT cTexto SIZE 580,390 FONT oFont OF oDlg PIXEL
		
	ACTIVATE MSDIALOG oDlg CENTERED

	
Return .T.
