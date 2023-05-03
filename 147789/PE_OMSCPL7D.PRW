// #########################################################################################
// Projeto: GTFOODS
// Fonte  : OMSCPL7D
// ---------+-------------------+-----------------------------------------------------------
// Data     | Autor				| Descricao
// ---------+-------------------+-----------------------------------------------------------
// 17/03/20 | Ricardo Mendes 	| P.E. padrão GFEA044 gatilhar informações para gerar Frete
// ---------+-------------------+-----------------------------------------------------------
#include 'totvs.ch'
#include 'parmtype.ch'

user function OMSCPL7D()
	Local aParam 	:= PARAMIXB
	Local lRet   	:= .T.
	Local cErro		:= ""

	If lRet
		// MIT044 - P02005 - SM083-IT06 - Integração OpenTech V01
		// Valida cadastros OpenTech e liberação da viagem
		lRet := U_F0200540(aParam, @cErro) 
	Endif	

	If lRet
		lRet := U_F0601301(aParam, @cErro)
	Endif	
	
	If lRet
		//MIT044  P04070 - SM086 - Cálculo de frete relacionado a despesas acessórias_V04
		//Validar os pedidos na DK1 e regra de frete para os pedidos.
		lRet := U_F0407010(aParam, @cErro)
	Endif

	If lRet
		//Validar se existe pesagem vinculada a viagem
		lRet := U_GTOMS007(aParam, @cErro)
	Endif		

Return {lRet, cErro}
