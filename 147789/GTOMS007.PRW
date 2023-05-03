/*/{Protheus.doc} User Function GTOMS007
    (long_description)
    @type  Function
    @author user
    @since 27/04/2023
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function GTOMS007(aParam, cErro)

Local cCodViag	:= aParam[1] //DK0_VIAGID
Local lRet		:= .T.
Local cQuery	:= ""
Local cAlias	:= ""
Local cPesag	:= ""

cErro := ""

if !(IsInCallStack("U_F04001E1") .OR. IsInCallStack("U_F0202010"))

    cQuery	:= "SELECT PC2_FILIAL FILIAL, PC2_CTRLE CONTROLE, PC2_VIAGEM VIAGEM "
    cQuery	+=  " FROM "+RetSqlName("PC2")+ " P "
    cQuery	+=  " LEFT JOIN "+RetSqlName("DK0")+ " D "
    cQuery	+=  " ON P.PC2_VIAGEM = D.DK0_VIAGID "
    cQuery	+=   " WHERE P.PC2_VIAGEM = '" + cCodViag + "' "
    cQuery	+=   " AND P.D_E_L_E_T_ = ' ' "
    cQuery	+=   " AND P.PC2_STATUS <> 'E' "

    cQuery	:= ChangeQuery(cQuery)
    cAlias	:= MPSysOpenQuery(cQuery)

    If (cAlias)->(!eof()) 
        
        Do While (cAlias)->(!Eof())  
            
            cPesag += (cAlias)->FILIAL+"-"+(cAlias)->CONTROLE+" /"

        (cAlias)->(dbSkip())
        EndDo
        
        cErro	:= "A Viagem "+ Alltrim(cCodViag) +" está vinculada a pesagem: " + cPesag 
        cErro	+= " É necessário cancelar a pesagem primeiramente, para ser possível gerar a carga."
        lRet 	:= .F.

    EndIF  

Endif

Return lRet
