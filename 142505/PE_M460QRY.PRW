#include "rwmake.ch" 

/*/{Protheus.doc} M460QRY - Adição de elementos em Query
@type  pe
@author Max Nascimento
@since 21/03/2023
@version 1.0
/*/

User Function M460QRY()

Local _volta  := ""
Local cQuery  := paramixb[1]
Local cCodQry := paramixb[2]

if FunName() == "MATA460A"
   _volta  := " AND SC9.C9_TPCARGA = '2'"
Else
   _volta  := " AND SC9.C9_TPCARGA = '1'"
Endif

If cCodQry == 1
   cQuery+=_volta
EndIf

Return(cQuery)
