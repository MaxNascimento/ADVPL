#Include 'Protheus.ch'

/*{Protheus.doc} MTA185MNU
O Ponto de Entrada MTA185MNU, Permite manipular as op��es do menu funcional da rotina de 
baixa de pr�-requisi��o.

@author    max.nascimento  
@since     31/01/2023
@version   1.0
@type      Ponto de entrada
*/

User Function MTA185MNU()

If Type( "aRotina" ) == "A"
    Aadd( aRotina, { 'Imprimir', 'A105Imprim', 0, 2, 0, Nil } )//Imprimir da rotina MATR105

EndIf

Return Nil
