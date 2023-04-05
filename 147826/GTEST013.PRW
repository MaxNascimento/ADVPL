#Include 'Totvs.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} GTEST013
@type  Function
@author Max Nascimento
@since 14/03/2023
@version 1.0
/*/

User Function GTEST013()

local cObs      := ""
Local cQuery    := ""
Local cAlias    := ""
Local cProduto  := ""

If IsInCallStack("A261Visual")
    cProduto  := aCols[1,1]
Else 
    cProduto  := aCols[1,2]
Endif

cQuery	:= "SELECT D3_OBSERVA OBSERVA"
cQuery	+=  " FROM "+RetSqlName("SD3")+ " SD3 "
cQuery	+=   " WHERE SD3.D3_DOC = '" + cDocumento + "' "
cQuery	+=   " AND SD3.D3_COD = '" + cProduto + "' "

cQuery	:= ChangeQuery(cQuery)
cAlias	:= MPSysOpenQuery(cQuery)

cObs := (cAlias)->OBSERVA

Return cObs
