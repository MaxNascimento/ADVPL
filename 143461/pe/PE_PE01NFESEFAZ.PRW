#include "protheus.ch"

/*/{Protheus.doc} PE01NFESEFAZ
//TODO Compõe a tag referente as observações da NF.
@author keler.melo
@since 01/10/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function PE01NFESEFAZ()
	Local aRetorno	 := PARAMIXB
	Local aProd		 := aRetorno[1]
	Local cMensCli	 := aRetorno[2]
	Local cMensFis	 := aRetorno[3]
	Local aDest		 := aRetorno[4]
	Local aNota		 := aRetorno[5]
	Local aInfoItem	 := aRetorno[6]
	Local aDupl		 := aRetorno[7]
	Local aTransp	 := aRetorno[8]
	Local aEntrega	 := aRetorno[9]
	Local aRetirada	 := aRetorno[10]
	Local aVeiculo	 := aRetorno[11]
	Local aReboque	 := aRetorno[12]
	Local aNfVincRur := aRetorno[13]
	Local aEspVol	 := aRetorno[14]
	Local aNfVinc	 := aRetorno[15]
	Local AdetPag	 := aRetorno[16]
	Local aObsCont	 := aRetorno[17]
	Local aDadosNfe
	
	
	aRetorno	 := {}

	U_F0401730( @aProd, @cMensCli, @cMensFis, @aDest, @aNota, @aInfoItem, @aDupl, @aTransp, @aEntrega, @aRetirada, @aVeiculo, @aReboque, @aNfVincRur, @aEspVol, @aNfVinc, @AdetPag, @aObsCont )	
	
	aadd( aRetorno, aProd	   )
	aadd( aRetorno, cMensCli   )
	aadd( aRetorno, cMensFis   )
	aadd( aRetorno, aDest	   )
	aadd( aRetorno, aNota	   )
	aadd( aRetorno, aInfoItem  )
	aadd( aRetorno, aDupl	   )
	aadd( aRetorno, aTransp	   )
	aadd( aRetorno, aEntrega   )
	aadd( aRetorno, aRetirada  )
	aadd( aRetorno, aVeiculo   )
	aadd( aRetorno, aReboque   )
	aadd( aRetorno, aNfVincRur )
	aadd( aRetorno, aEspVol	   )
	aadd( aRetorno, aNfVinc	   )
	aadd( aRetorno, AdetPag	   )
	aadd( aRetorno, aObsCont   )
		
		
	//Função para Atualização dos Registros dos Lacres relacionando com a Repectiva Nota Fiscal
	aDadosNfe 	:= aRetorno
	aRetorno 	:= U_G0513603( aDadosNfe )
	

	aDadosNfe 	:= aRetorno
	aRetorno 	:= U_SM026(aDadosNfe)
	

	// SM086 - Valor do Frete e ICMS do Frete Autônomo	
	aDadosNfe 	:= aRetorno
	aRetorno	:= U_F0407040(aDadosNfe, aNota)


	//Adiciona mensagem complementares nas notas de venda e remessa - Ronaldo Dantas
	aDadosNfe 	:= aRetorno
	aRetorno	:= U_F0407220(aDadosNfe, aNota)	
	
RETURN aRetorno
