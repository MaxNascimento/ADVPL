#INCLUDE "rwmake.ch"

/*/{Protheus.doc} M410INIC - 
@type  pe
@author Max Nascimento
@since 21/03/2023
@version 1.0
/*/

User Function M410INIC()

If FunName() == "MATA410"
    M->C5_TPCARGA := ''
    M->C5_TPFRETE := ''
Endif

Return Nil
