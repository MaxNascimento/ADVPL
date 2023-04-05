#INCLUDE'Protheus.ch'
#DEFINE USADO CHR(0)+CHR(0)+CHR(1)

/*/{Protheus.doc} MA261CPO
@type  pe
@author Max Nascimento
@since 14/03/2023
@version 1.0
/*/
User Function MA261CPO()
 
Local aTam := {}

aTam := TamSX3('D3_OBSERVA')
Aadd(aHeader, {RetTitle('D3_OBSERVA'), 'D3_OBSERVA', PesqPict('SD3', 'D3_OBSERVA', aTam[1] ), aTam[1], aTam[2],"" , USADO, 'C', 'SD3', ''})

Return Nil
