#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'ParmType.ch'
 
/*/{Protheus.doc} MT103FIN
//TODO Opera��o ap�s grava��o da NF de entrada.

@author 	Alex Lima
@since 		07/11/2018
@version 	P12.17
@type 		Function
@project 	0000032563
  
/*/ 
User Function MT103FIN()
	Local lRet 		:= .T.
	
	If lRet
	    // Fun��o desenvolvida pelo analista Gerson ADA - FSW-GT
	    if FindFunction("U_G0501606") //Bloqueios de titulos GAP016	
	    	lRet := U_G0501606()
	    endif
	Endif

	If lRet
	   
	    if FindFunction("U_GTFAT030") // @MayconMotta  Valida��o do chamado 131608
	    	lRet := U_GTFAT030()
	    endif
	Endif

Return lRet 
