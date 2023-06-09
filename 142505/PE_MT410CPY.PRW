#include "rwmake.ch"
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � MT410CPY �Autor  �Miguel Fran�a       � Data �  14/08/13   ���
�������������������������������������������������������������������������͹��
���Desc.     �Ponto de entrada na copia de um pedido de venda para limpar ���
���          �os campos especificos                                       ���
�������������������������������������������������������������������������͹��
���Uso       � Igaratiba                                                  ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function MT410CPY()

	Local aArea := GetArea()
	Local lRet := .T.
	Local nPosTES := GDFIELDPOS("C6_TES") // PEGA A POSI��O DO ARRAY DA SC6
	Local nPosCF := GDFIELDPOS("C6_CF") // PEGA A POSI��O DO ARRAY DA SC6
	Local nx := 0

	M->C5_YCDPALM 	:= ""
	M->C5_FRETAUT	:= 0
	M->C5_XVALFRE 	:= 0
	M->C5_XICMFRE	:= 0
	M->C5_XAICFRE	:= 0
	M->C5_XPEDMAE	:= ""
	M->C5_TPCARGA 	:= ""
    M->C5_TPFRETE 	:= ""
	
// LIMPA OS CAMPOS TES E CF NO ARRAY DA SC6

	IF  nPosTES <> 0 .AND. nPosCF <> 0
		For nx := 1 To Len(aCols)
			aCols[nx][nPosTES] := " " 
			aCols[nx][nPosCF] := " "
		Next nx
	endif

	RestArea(aArea) 
RETURN lRet

