#Include 'Protheus.ch'

/*/{Protheus.doc} FA090SE5
//TODO Ponto de Entrada para manipular filtro que seleciona os registros de adiantamentos e/ou notas de débito do fornecedor.
@author max.nascimento
@since 02/12/2022
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
 
User Function F090ADFR()
 
    Local cCondicao := PARAMIXB[1]
    Local lMultFilial := PARAMIXB[2]
    Local aReturn := {}

        cCondicao := "(E2_TIPO $ '"+MV_CPNEG + "/" + MVPAGANT+ "') .And. E2_SALDO > 0 "
        cCondicao += " .And. Empty(E2_BAIXA) "

        lMultFilial := .T.
 
    AADD(aReturn,cCondicao)
    AADD(aReturn,lMultFilial)
 
Return aReturn
