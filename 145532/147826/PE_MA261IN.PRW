#Include 'Protheus.ch'
 
 /*/{Protheus.doc} MA261IN
@type  pe
@author Max Nascimento
@since 14/03/2023
@version 1.0
/*/
User Function MA261IN()

Local nPosCampo := aScan(aHeader, {|x| AllTrim(Upper(x[2]))=='D3_OBSERVA'})

if IsInCallStack("A261Visual")  .or. IsInCallStack("A261Estorn")
    IF FINDFUNCTION("U_GTEST013")  
		aCols[len(aCols),nPosCampo] := U_GTEST013()
	ENDIF
endif

Return Nil
