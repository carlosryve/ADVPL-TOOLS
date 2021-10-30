#include "Rwmake.ch"
#include "Protheus.ch"

Static _cRetConp

/*
	Autor       : Caio Renan
	Data/Time   : 04/04/14
	Detalhe     : Funcao para uma consulta customizada atraves de um select e um arquivo de configuracao

	Ajustes     : Carlos Ryve Gandini
	Data/Time   : 30/10/21 ‡s 11:30:45
	Detalhe     : Melhorias de perfomance

	No final desse fonte tem um exemplo de um arquivo usando todos os parametros funcionalidades instaladas.
	Ao mudar a pesquisa, reordena o array com os dados.
	Adicionado a opcao para definir o tamanho da tela - TAMANHO_TELA_COLUNA

	U_CONSFILE("\consulta\consulta_produto.txt")

	Funcao para retorno - maiores informaÁıes vide funcao abaixo
	U_RETCONSF()

*/

User Function CONSFILE(_cArquivo)
Local _aArea := GetArea()
Local oButton1
Local oButton2
Local oButton3
Local oComboBo1
Local nComboBo1 := "1"
Local oGet1
Local cGet1 := Space(100)

Local _aHeader := {}
Local _aSize := {}
Local _aCampo := {}

Local _aLinhas := LeArq(_cArquivo)
Local _nPICol := AScan(_aLinhas , {|x| "--INI_COLUNAS" $ x } ) + 1
Local _nPFCol := AScan(_aLinhas , {|x| "--FIM_COLUNAS" $ x } ) - 1

Local _nPIPesq := AScan(_aLinhas , {|x| "--INI_PESQUISAS" $ x } ) + 1
Local _nPFPesq := AScan(_aLinhas , {|x| "--FIM_PESQUISAS" $ x } ) - 1

Local _aItens := {}
Local _aItCmp := {}

Local _nSizeC := AScan(_aLinhas , {|x| "--TAMANHO_TELA_COLUNA"   $ x } ) + 1

If Empty(_aLinhas)
	Return(.F.)
EndIf

Private _nOpc := 0

Private oDlg

Private oWBrowse1
Private aWBrowse1 := {}
Private aWBrFilt := {}

Private _cNReg := ""  // numero de registros encontrado
Private _oSReg := Nil // numero de registros encontrado

If _nSizeC == 1
	_nSizeC := 500
Else
	_nSizeC := Val(_aLinhas[_nSizeC])
	If _nSizeC < 500
		_nSizeC := 500
	EndIf
EndIf

_cTitle := _aLinhas[ AScan(_aLinhas , {|x| "--TITULO_JANELA" $ x } ) + 1 ]

For _nx := _nPICol To _nPFCol

	// 3 posicoes - Titulo coluna | Tamanho | Campo
	_aColuna := StrTokArr(_aLinhas[_nx] , ",")
	
	Aadd(_aHeader , _aColuna[01] )
	Aadd(_aSize   , _aColuna[02] )
	Aadd(_aCampo  , _aColuna[03] )
Next

_nCont := 0
For _nx := _nPIPesq To _nPFPesq
	_nCont++
	
	// 2 posicoes - Titulo da pesquisa | Campo a ser pesquisa
	_aPesq := StrTokArr(_aLinhas[_nx] , ",")
	
	Aadd( _aItens , StrZero(_nCont,02)+"="+_aPesq[01] )
	
	Aadd( _aItCmp , {} )
	For _ny := 2 to Len(_aPesq)
		Aadd( _aItCmp[Len(_aItCmp)] , _aPesq[_ny] )
	Next
	
Next

_cAlias := fExeSql(_aLinhas,_aHeader,_aSize,_aCampo,_nSizeC)

_cReadVar := &(ReadVar())

// criaÁ„o da tela
DEFINE MSDIALOG oDlg TITLE _cTitle FROM 000, 000  TO 485, _nSizeC COLORS 0, 16777215 PIXEL

FWMsgRun( /* Obj_tela */ , {|oSay| fWBrowse1(_aLinhas,_aHeader,_aSize,_aCampo,_nSizeC, _cAlias) } ,  , "Caregando consulta.." )

@ 225, 02 SAY _oSReg Prompt _cNReg SIZE 50,15 of oDlg pixel

@ 005, 002 MSCOMBOBOX oComboBo1 VAR nComboBo1 ITEMS _aItens SIZE 072, 010 OF oDlg COLORS 0, 16777215 PIXEL
oComboBo1:bChange := {|| FWMsgRun( /* Obj_tela */ , {|oSay| fOrdena(nComboBo1, _aItCmp, _aCampo) } ,  , "Ordenando registros..." ) }

cGet1 := PadR(_cReadVar, 100)
@ 005, 077 MSGET oGet1 VAR cGet1 SIZE (_nSizeC * 0.304) , 010 OF oDlg COLORS 0, 16777215 PIXEL

If !Empty(cGet1)
	fPesquisa(_aItCmp, nComboBo1 ,cGet1, _aCampo,oGet1)
EndIf

@ 005, (_nSizeC * 0.462) BUTTON oButton3 PROMPT ">>" SIZE 014, 012 Action(fPesquisa(_aItCmp, nComboBo1 ,cGet1, _aCampo,oGet1)) OF oDlg PIXEL
oButton3:bAction := {|| FWMsgRun( , {|oSay| fPesquisa(_aItCmp, nComboBo1 ,cGet1, _aCampo,oGet1) } ,  , "Pesquisando..." ) }

@ 225, 153 BUTTON oButton1 PROMPT "Ok" SIZE 037, 012 Action( fRetorna(_aLinhas,_aCampo) ) OF oDlg PIXEL
oWBrowse1:bLDblClick := {|| fRetorna(_aLinhas,_aCampo) }

@ 225, 200 BUTTON oButton2 PROMPT "Cancelar" SIZE 037, 012 Action(oDlg:End()) OF oDlg PIXEL

FWMsgRun( /* Obj_tela */ , {|oSay| fOrdena(nComboBo1, _aItCmp, _aCampo) } ,  , "Ordenando registros..." )

oGet1:SetFocus()

ACTIVATE MSDIALOG oDlg CENTERED
If _nOpc == 1
Else
	_cRetConp := ""
EndIf

RestArea(_aArea)

Return !(empty(_cRetConp))


/*/
@author: caiocrol
@data: 19/11/2014
@descricao: Tratativa de retorno da consulta, permite ter varios retornos
_nPRetBrow -- Posicao da coluna que sera retornanda
se maior que 0 apenas um retorno, se nao
/*/
Static Function fRetorna(_aLinhas,_aCampo)
Local _nPIRet := AScan(_aLinhas , {|x| "--RETORNO_CONSULTA"    $ x } ) + 1 // inicio retorno
Local _nPFRet := AScan(_aLinhas , {|x| "--FIM_RETORNO_CONSULTA"    $ x } ) // fim retorno

Local _nPRetBrow := 0 
Local _aRetCon := {}
Local _nx := 0

_nOpc := 1

If _nPFRet = 0
	_nPRetBrow := AScan(_aCampo , {|x|  _aLinhas[_nPIRet]   $ x } )
	_cRetConp := aWBrFilt[oWBrowse1:nAt , _nPRetBrow]
Else
	_nPFRet--
	For _nx := _nPIRet To _nPFRet
		// 1 posicao , coluna que sera retornada
		Aadd(_aRetCon , _aLinhas[_nx] )
	Next
	
	_cRetConp := ""
	
	For _nx := 1 To Len(_aRetCon)
		_nPRetBrow := AScan(_aCampo , {|x|  _aRetCon[_nx]   $ x } )
		_cRetConp += aWBrFilt[oWBrowse1:nAt , _nPRetBrow]+";"
	Next
	
	// retira ponto e virgual final
	If Right(_cRetConp , 1) == ";"
		_cRetConp := Left(_cRetConp , Len(_cRetConp) - 1)
	EndIf
	
EndIf

oDlg:End()

Return

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao para ordenacao - os campo utilizados para ordencao devem estar no browser
// nComboBo1 - Opcao de pesquisa selecionada 
// _aItCmp   - campos que compoe a chave de ordenacao
// _aCampo   - campos do browse
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fOrdena(nComboBo1, _aItCmp, _aCampo)

Local _aCmpI := _aItCmp[Val(nComboBo1)]
Local _aNPos := {}

For _nz := 1 To Len(_aCmpI)
	_nPos := aScan(_aCampo , _aCmpI[_nz]  )
	If _nPos > 0
		Aadd(_aNPos , _nPos )
	EndIf
Next

aSort( aWBrFilt ,,, {|x,y| fOrdAux(x , y , _aNPos, _aCampo ) } )

oWBrowse1:Refresh()
oDlg:Refresh()

Return

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao auxiliar para ordencao
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fOrdAux(_x, _y, _aNPos, _aCampo)
Local _lRet := .T.
Local _cX := ""
Local _cY := ""

For _nz := 1 To Len(_aNPos)
	_cX += _x[_nPos]
	_cY += _y[_nPos]
Next

_lRet := _cX < _cY

Return _lRet

/*
//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao para ordenacao - os campo utilizados para ordencao devem estar no browser
// nComboBo1 - Opcao de pesquisa selecionada 
// _aItCmp   - campos que compoe a chave de ordenacao
// _aCampo   - campos do browse
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fOrdena(nComboBo1, _aItCmp, _aCampo)

Local _aCmpI := _aItCmp[Val(nComboBo1)]
Local _aNPos := {}

For _nz := 1 To Len(_aCmpI)
	_nPos := aScan(_aCampo , _aCmpI[_nz]  )
	If _nPos > 0
		Aadd(_aNPos , _nPos )
	EndIf
Next

aSort( aWBrFilt ,,, {|x,y| fOrdAux(x , y , _aCmpI, _aCampo ) } )

oWBrowse1:Refresh()
oDlg:Refresh()

Return

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao auxiliar para ordencao
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fOrdAux(_x, _y, _aItCmp, _aCampo)
Local _lRet := .T.
Local _nPos := 0
Local _cX := ""
Local _cY := ""

For _nz := 1 To Len(_aItCmp)
	_nPos := aScan(_aCampo , {|x| _aItCmp[_nz] = x }  )
	If _nPos > 0
		_cX += _x[_nPos]
		_cY += _y[_nPos]
	EndIf
Next

_lRet := _cX < _cY

Return _lRet
*/

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao
// _aItCmp - array com os campos que fazem parte dessa pesquisa (multidimensional)
// nComboBo1 - caractere - indice de pesquisa selecionado - codigo
// cGet1 - o que foi digitado na pesquisa
// _aCampo - array com os campos que estao no browse
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fPesquisa(_aItCmp,nComboBo1,cGet1, _aCampo,oGet1)
Local _aCmpI := _aItCmp[Val(nComboBo1)]
Local _na := 0
Local _aBrwFilt := {}

If Empty(cGet1) // se vazio limpa o filtro
	aWBrFilt := aClone(aWBrowse1)
	
Else
	
	For _na:= 1 to Len(aWBrowse1)
		If fPesqAux(aWBrowse1[_na], cGet1, _aCmpI, _aCampo)
			Aadd(_aBrwFilt , aWBrowse1[_na] )
		EndIf
	Next
	
	If Len(_aBrwFilt) > 0
		aWBrFilt := aClone(_aBrwFilt)
		oWBrowse1:SetFocus()
	Else
		oGet1:SetFocus()
		aWBrFilt := aClone(aWBrowse1)
		MsgAlert("N„o encontrado")
	EndIf
	
EndIf

_cNReg := cValToChar(Len(aWBrFilt)) + " Registro(s)"

oWBrowse1:SetArray(aWBrFilt)
oWBrowse1:bLine := {|| fbLine() }
oWBrowse1:DrawSelect()

fOrdena(nComboBo1, _aItCmp, _aCampo)

If Len(aWBrFilt) > 0
	oWBrowse1:nAt := 1
EndIf

/* para mudar descricao da tela se usa oSay:cCaption := "" dentro da funcao a ser executada */
//FWMsgRun( /* Obj_tela */ , {|oSay| Funcao_a_ser_executada } , Titulo , Mensagem )

/*
Alert(VarInfo("_aItCmp", _aItCmp , , .F. ))
Alert(VarInfo("nComboBo1", nComboBo1 , , .F. ))
Alert(VarInfo("cGet1", cGet1 , , .F. ))
Alert(VarInfo("_aCampo", _aCampo , , .F. ))
*/

Return

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao auxiliar para pesquisa
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fPesqAux(_x, cGet1, _aItCmp, _aCampo)
Local _lRet := .T.
Local _nPos := 0
Local _cX := ""

For _nz := 1 To Len(_aItCmp)
	_nPos := aScan(_aCampo , {|x| _aItCmp[_nz] == x }  )
	If _nPos > 0
		_cX += _x[_nPos]
	EndIf
Next

_lRet := NoAcento(UPPER(AllTrim(cGet1))) $ NoAcento(UPPER(AllTrim(_cX)))

Return _lRet

/*
//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao
// _aItCmp - array com os campos que estao no browse (multidimensional)
// nComboBo1 - caractere - indice de pesquisa selecionado - codigo
// cGet1 - o que foi digitado na pesquisa
// _aCampo - array com os campos que estao no browse
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fPesquisa(_aItCmp,nComboBo1,cGet1, _aCampo)
Local _aCmpI := _aItCmp[Val(nComboBo1)]
Local _nPos := aScan(aWBrFilt , {|x| fPesqAux(x, cGet1, _aCmpI , _aCampo) } ) 

Alert(VarInfo("_aItCmp", _aItCmp , , .F. ))
Alert(VarInfo("nComboBo1", nComboBo1 , , .F. ))
Alert(VarInfo("cGet1", cGet1 , , .F. ))
Alert(VarInfo("_aCampo", _aCampo , , .F. ))

If _nPos > 0
	oWBrowse1:nAt := _nPos 
Else
	MsgAlert("N„o encontrado")
EndIf
Return

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao auxiliar para pesquisa
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fPesqAux(_x, cGet1, _aItCmp, _aCampo)
Local _lRet := .T.
Local _nPos := 0
Local _cX := ""

For _nz := 1 To Len(_aItCmp)
	_nPos := aScan(_aCampo , {|x| _aItCmp[_nz] = x }  )
	If _nPos > 0
		_cX += _x[_nPos]
	EndIf
Next

_lRet := AllTrim(cGet1) $ AllTrim(_cX)

//aScan(_aCampo , {|x| AllTrim(_aPesq[02]) $ x }  )

Return _lRet
*/

Static Function fSelect()
	
Return nil

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fExeSql(_aLinhas,_aHeader,_aSize,_aCampo,_nSizeC)
Local _cSql := ""
Local _cALias := GetNextAlias()

Local _nPTabela := AScan(_aLinhas , {|x| "--TABELA" $ x } ) + 1
Local _nPFilt   := AScan(_aLinhas , {|x| "--TABELA_FILTRO" $ x } ) + 1

Local _nPISQL := AScan(_aLinhas , {|x| "--INICIO_SQL" $ x } ) + 1
Local _nPFSQL := AScan(_aLinhas , {|x| "--FIM_SQL"    $ x } ) - 1

Local _nPIPSQL := AScan(_aLinhas , {|x| "--INICIO_PARAM_SQL" $ x } ) + 1
Local _nPFPSQL := AScan(_aLinhas , {|x| "--FIM_PARAM_SQL"    $ x } ) - 1

// PARA pesquisa dbf ou ctree deve-se usar a tag --TABELA
If _nPTabela > 1
	_cALias := _aLinhas[_nPTabela]
	dbSelectArea(_cALias)
	If _nPFilt > 1
		SET FILTER TO &(_aLinhas[_nPFilt])
	EndIf
Else
	// String SQL
	For _nx :=  _nPISQL To _nPFSQL
		_cSql += _aLinhas[_nx] + " "
	Next
	// Parametros que serao usados no sql
	For _nx :=  _nPIPSQL To _nPFPSQL
		_aParamSql := StrTokArr(_aLinhas[_nx],";")
		_cSql := StrTran( _cSql, _aParamSql[01] , &(_aParamSql[02]) )
	Next

	If Select(_cALias) > 0
		(_cALias)->(dbClosearea())
	Endif
	MemoWrite("D:\LOGSQL\CONSFILE.txt" , _cSql)
	DbUseArea(.T., "TOPCONN", TCGenQry(,,ChangeQuery(_cSql)), _cALias, .F., .F.)
	
EndIf
Return(_cALias)

/*/{Protheus.doc} fWBrowse1
carrega os dados no array do twbrowse
@author caio.lima
@since 07/05/2018
@param _aLinhas, , descricao
@param _aHeader, , descricao
@param _aSize, , descricao
@param _aCampo, , descricao
@param _nSizeC, , descricao
@param _cALias, , descricao
@return return, return_description
/*/
Static Function fWBrowse1(_aLinhas,_aHeader,_aSize,_aCampo,_nSizeC, _cALias)

(_cALias)->(dbGoTop())

If (_cALias)->(Eof())
	Aadd(aWBrowse1, {} )
	For _nx := 1 To Len(_aCampo)
		Aadd(aWBrowse1[Len(aWBrowse1)], "" )
	Next
EndIf

While !(_cALias)->(Eof())
	Aadd(aWBrowse1, {} )
	
	For _nx := 1 To Len(_aCampo)
		Aadd(aWBrowse1[Len(aWBrowse1)], (_cALias)->&(_aCampo[_nx]) )
	Next
	
	(_cALias)->(dbSkip())
EndDo

If Len(_cAlias) > 3
	(_cAlias)->( dbCloseArea() )
EndIf

aWBrFilt := aClone(aWBrowse1)

_cNReg := cValToChar(Len(aWBrFilt)) + " Registro(s)"

oWBrowse1 := TWBrowse():New(  021, 002, (_nSizeC * 0.49), 199 ,,_aHeader,_aSize,oDlg ,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

oWBrowse1:SetArray(aWBrFilt)

oWBrowse1:bLine := {|| fbLine() }

// DoubleClick event
//oWBrowse1:bLDblClick := {|| aWBrowse1[oWBrowse1:nAt,1] := !aWBrowse1[oWBrowse1:nAt,1],;
//oWBrowse1:DrawSelect()}
Return
//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function fbLine()
Local _aRet := {}
For _nz := 1 to Len(aWBrFilt[oWBrowse1:nAt])
	Aadd(_aRet,aWBrFilt[oWBrowse1:nAt,_nz])
Next
Return(_aRet)
//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao que le o arquivo e retorna um array com todos as linhas do arquivo
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function LeArq(_cArquivo)
Local _aLinhas := {}
// Abre o arquivo
If Empty(_cArquivo)
	nHandle := FT_FUse("\system\consulta_sramultemp.txt")
	Else
	nHandle := FT_FUse(_cArquivo)
EndIf
// Se houver erro de abertura abandona processamento
if nHandle = -1
	Alert("N„o foi possivel abrir o arquivo de configuracao da consulta" + CRLF + _cArquivo)
	return
endif
// Posiciona na primeria linha
FT_FGoTop()
// Retorna o n˙mero de linhas do arquivo
//nLast := FT_FLastRec()
While !FT_FEOF()
	cLine  := FT_FReadLn()
	Aadd(_aLinhas, cLine)
	// Pula para prÛxima linha
	FT_FSKIP()
EndDo
// Fecha o Arquivo
FT_FUSE()

Return(_aLinhas)
//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
// funcao
// para multiplo retorno adicionar varias vezes: U_RETCONSF(1,2) U_RETCONSF(3,2) ... ** OLD not use
// parametros posicao inicial e quantidade de caracteres que vai pegar               ** OLD not use
//
// para retorno unico colocar no cadastro de retorno da consulta especifica: U_RETCONSF()
// para varios retornos deve ser colocado ao numero do retorno
// exemplo abaixo
// --RETORNO_CONSULTA
//X6_VAR      // como deve ficar no retorno da consulta U_RETCONSF(1)
//X6_DESCRIC  // como deve ficar no retorno da consulta U_RETCONSF(2)
//X6_DESC1    // como deve ficar no retorno da consulta U_RETCONSF(3)
//X6_DESC2    // como deve ficar no retorno da consulta U_RETCONSF(4)
//--FIM_RETORNO_CONSULTA
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
// U_RETCONSF()
User Function RETCONSF(_nLinha)
Local _aRet := {}
Local _cRet := _cRetConp

Default _nLinha := 0

If At(";" , _cRetConp) > 0 .AND. _nLinha > 0
	_aRet := StrTokArr(_cRetConp , ";")
	_cRet := _aRet[_nLinha]
EndIf

Return(_cRet)

/*/{Protheus.doc} RetStatVar
Funcao para retornar a variavel estatica de retorno
@author caio.lima
@since 07/11/2017
@return caractere, variavel static
/*/
User Function RetStatVar()
Return(_cRetConp)

/*
EXEMPLO DE UM ARQUIVO TXT COM AS CONFIGURACOES NECESSARIAS
--INICIO_PARAM
--TITULO_JANELA
Consulta Funcion·rio
--RETORNO_CONSULTA
EMPFILMAT
--TAMANHO_TELA_COLUNA
700
--INI_PESQUISAS
Empresa,EMPRESA
Matricula,RA_MAT
Nome,RA_NOME
EmpFilMat,EMPFILMAT
--FIM_PESQUISAS
--INI_COLUNAS
Empresa,5,EMPRESA
Filial,5,RA_FILIAL
Matricula,10,RA_MAT
Nome,50,RA_NOME
Emp Fil Mat,15,EMPFILMAT
--FIM_COLUNAS
--FIM_PARAM
--INICIO_SQL
SELECT * FROM SRAMULTEMP
--FIM_SQL
--INICIO_PARAM_SQL
01,ACOLS[N,ASCAN(AHEADER,{|| X[02]=="AF8_PROJET" })]
--FIM_PARAM_SQL
*/
