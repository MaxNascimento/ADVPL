#Include 'Protheus.ch'
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOTVS.CH"


User Function A010TOK  ()
	Local bExec 	:= .T.
	Local cTabela 	:= ""
	Local cCampo 	:= ""


	If !IsInCallStack("u_F0600103")		
		If FindFunction("u_ipgPE")
			bExec 	:= u_ipgPE("A010TOK")
			cTabela	:= 'SB1'
			cCampo 	:= u_prefTb(cTabela)
			
			Conout(" ***** Ponto de Entrada A010TOK GEOSALES Executado"+" - "+DTOC(DATE())+" - "+TIME())
			
			If bExec
				Conout("bExec TRUE GEOSALES"+" - "+DTOC(DATE())+" - "+TIME())
				u_delaySend(cTabela)
			EndIf
		Endif
	EndIf

	If bExec 
		bExec := U_GTFAT041()//Validação do campo Peso
		If !bExec
			Return(bExec)
		Endif
	EndIf
	
Return bExec
