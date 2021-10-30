#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TABPROT
Funcao para consultas no dicionario de dados.
@author Caio.Lima
@since 16/03/2020

@return return, return_description
/*/
User Function TABPROT()

	Private _cVersao := GetSRVProfString("RPOVERSION", "INVALIDO")
	Private _cDbExt := GetSRVProfString("localdbextension", ".dbf")

	Private _aScrRes := GetScreenRes()
	Private dDataBase := MsDate()

	SetFlatControls(.F.)
	MsApp():New('SIGAFAT')
	oApp:CreateEnv()
	oApp:bMainInit := {|| fMainApp() }
	oApp:bAppStart := {|| fIniApp() }
	oApp:cModDesc	:= "Full_Name"
	oApp:cModulo	:= "Module_name" 

	ptSetTheme("MDI")
	__lInternet := .T.

	SetMDIChild(0)

	oApp:Activate()

	fMainApp()

Return

/*/{Protheus.doc} fChooseSM0
funcao para listar as tabels SX2
@author Caio.Lima
@since 16/03/2020

@return return, return_description
/*/
Static Function fChooseSM0()
	Local _aCoor := MsAdvSize(.F.)
	Local _a1 := {_aCoor[1],_aCoor[2],_aCoor[3],_aCoor[4],3,3}
	Local _a2 := { {37,12,.F.,.F.,.T.}, {200,200,.T.,.T.,.T.} }
	Local _aObj := MsObjSize(_a1 , _a2 , .T. , .F. )
	Local _nx := 0

	Local _cRDD := "CTREECDX"
	Local _cAlTab := "SM0"
	Local _cTab   := ""
	Local oBrow
	Local _tela

	// para fixar um tamanho de tela
	_aCoor[5] := 600 // largura da janela
	_aCoor[6] := 400 // altura da janela
	_aCoor[3] := _aCoor[5] / 2
	_aCoor[4] := _aCoor[6] / 2

	_a1 := {_aCoor[1],_aCoor[2],_aCoor[3],_aCoor[4],3,3}
	_a2 := { {37,12,.F.,.F.,.T.}, {200,200,.T.,.T.,.T.} }
	_aObj := MsObjSize(_a1 , _a2 , .T. , .F. )

	DbUseArea(.T., _cRDD, "\system\sigamat.emp" , "SM0", .T., .T.)
	dbSelectarea(_cAlTab)
	_aStruct := (_cAlTab)->(dbStruct())

	DEFINE MSDIALOG _tela TITLE "sigamat" FROM 000, 000  TO _aCoor[6],_aCoor[5] COLORS 0, 16777215 PIXEL

	@ _aObj[1,1],_aObj[1,2] SAY "Selecione a empresa para abrir o dicionario." OF _tela PIXEL

	oBrow := MsBrGetDBase():New( _aObj[2,1],_aObj[2,2],_aObj[2,3],_aObj[2,4],,,, _tela,,,,,,,,,,,, .F., _cAlTab, .T.,, .F.,,, )

	For _nx:= 1 to Len(_aStruct)
		oBrow:AddColumn( TCColumn():New( _aStruct[_nx,01]   , &("{ || "+_cAlTab+"->"+_aStruct[_nx,01]+" }")  ,,,,,.F.) )
	Next
	oBrow:bLDblClick := {|| _tela:End() }
	oBrow:Refresh()

	ACTIVATE MSDIALOG _tela CENTERED

	//Alert(SM0->M0_CODIGO)

Return

/*/{Protheus.doc} fMainApp
funcao para listar as tabels SX2
@author Caio.Lima
@since 16/03/2020

@return return, return_description
/*/
Static Function fMainApp()
	Local _aCoor := MsAdvSize(.F.)
	Local _a1 := {_aCoor[1],_aCoor[2],_aCoor[3],_aCoor[4],3,3}
	Local _a2 := { {37,14,.F.,.F.,.T.}, {45,12,.F.,.F.,.T.}, {200,200,.T.,.T.,.T.} }
	Local _aObj := MsObjSize(_a1 , _a2 , .T. , .F. )
	Local _nx := 0

	Local _cRDD := "CTREECDX"
	Local _cAlTab := "SX2"
	Local _cTab   := ""
	Local oBrow, oCampo, oValor, oAllF, oBusca
	Local cCampo := PadR("X2_CHAVE",12)
	Local cValor  := PadR("",30)
	//DbUseArea(.T., _cRDD, "\system\sigamat.emp" , "SM0", .T., .T.)
	//dbSelectarea("SM0")

	fChooseSM0()

	_cTab   := "\system\sx2"+SM0->M0_CODIGO+"0.dtc"

	DbUseArea(.T., _cRDD, _cTab , _cAlTab, .T., .T.)
	dbSelectarea(_cAlTab)
	_aStruct := (_cAlTab)->(dbStruct())

	@ _aObj[2,1],_aObj[2,2] MsGet oCampo Var cCampo Size _aObj[2,3],_aObj[2,4] PIXEL HASBUTTON OF oMainWnd 
	@ _aObj[2,1],_aObj[2,2] + 50 MsGet oValor Var cValor Size 100,_aObj[2,4] PIXEL HASBUTTON OF oMainWnd
	oValor:cToolTip := "Para pesquisar mais de um resultado por vez utilize separado por virgula ex.: SC5,SC6"
	@ _aObj[2,1],_aObj[2,2] + 50 + 105 Button oBusca Prompt "Buscar" Action(fRunFilt(_cAlTab, cCampo, cValor, ,oValor,oBrow)) Size 40,_aObj[2,4] PIXEL OF oMainWnd 
	@ _aObj[2,1],_aObj[2,2] + 50 + 105 + 45 Button oAllF Prompt "Todos os campos" Action(fCampos(.T.)) Size 50,_aObj[2,4] PIXEL OF oMainWnd
	
	@ _aObj[2,1], _aObj[3,3] - (45 * 2) Button oExecSQL Prompt "ExecSQL" Action( fCallProc() ) Size 40,_aObj[2,4] PIXEL OF oMainWnd
	@ _aObj[2,1], _aObj[3,3] - 45 Button oClose Prompt "Fechar"  Action( oMainWnd:End() ) Size 40,_aObj[2,4] PIXEL OF oMainWnd

	oBrow := MsBrGetDBase():New( _aObj[3,1],_aObj[3,2],_aObj[3,3],_aObj[3,4],,,, oMainWnd,,,,,,,,,,,, .F., _cAlTab, .T.,, .F.,,, )

	For _nx:= 1 to Len(_aStruct)
		oBrow:AddColumn( TCColumn():New( _aStruct[_nx,01]   , &("{ || "+_cAlTab+"->"+_aStruct[_nx,01]+" }")  ,,,,,.F.) )
	Next

	oBrow:bLDblClick := {|| FWMsgRun( /* Obj_tela */ , {|oSay| fCampos() } , "Abrindo campos" , "Tabela: " + SX2->X2_CHAVE ) }
	oBrow:Refresh()
	oValor:SetFocus()
	
Return

/*/{Protheus.doc} fCallProc
Chama função 
@author Caio.Lima
@since 19/11/2020
/*/
Static Function fCallProc()
	Local cInifile := GetADV97()
	Local _cServer   := GetServerIP()
	Local _cPorta    := GetPvProfString("TCP","PORT","ERROR",cInifile )
	Local _cProgram  := "U_EXECSQL"
	Local _cAmbiente := GetEnvServer()
	Local _cExec := ""
	Local _cIniName:= GetRemoteIniName()
	Local lUnix:= IsSrvUnix()
	Local _nPosBar := Rat( IIf(lUnix,"/","\"),_cIniName )
	Local _cPathRmt:= Substr( _cIniName,1,_nPosBar-1 )

	_cExec := _cPathRmt + "\smartclient.exe"
	_cExec += " -q -m -z="+_cServer+" -y="+_cPorta+" -p="+_cProgram+" -e="+_cAmbiente
	//Aviso( 'VarInfo', _cExec ,{'ok'} ,4,,,, .T.)
	WinExec(_cExec)

Return

/*/{Protheus.doc} fCampos
funcao para listar os campos SX3
@author Caio.Lima
@since 16/03/2020

@return return, return_description
/*/
Static Function fCampos(_lAll)
	Local _aCoor := MsAdvSize(.F.)
	Local _a1, _a2, _aObj
	Local _nx := 0

	Local _cRDD := "CTREECDX"
	Local _cAlTab := "SX3"
	Local _cAlSIX := "SIX"
	Local _cTab   := ""
	Local oBrow, oCampo, oValor, oFolder, oBrwSIX, oBusca
	Local cCampo := PadR("X3_CAMPO",12)
	Local cValor  := PadR("",30)
	Local _tela
	Local _cFixo := ""
	Local _cFiltSX3 := ""
	Local _cFiltSIX := ""
	Local _oFTab, _cFTab := ""
	Local _aCampos := {"X3_ARQUIVO","X3_ORDEM","X3_CAMPO","X3_TIPO","X3_TAMANHO","X3_DECIMAL","X3_TITULO","X3_DESCRIC","X3_PICTURE","X3_VALID","X3_USADO","X3_RELACAO","X3_F3","X3_NIVEL","X3_CHECK","X3_TRIGGER","X3_PROPRI","X3_BROWSE","X3_VISUAL","X3_CONTEXT","X3_OBRIGAT","X3_VLDUSER","X3_CBOX","X3_PICTVAR","X3_WHEN","X3_INIBRW","X3_GRPSXG"}
	Default _lAll := .F.

	// para fixar um tamanho de tela
	_aCoor[5] := _aCoor[5] - 100 // largura da janela
	_aCoor[6] := 650 // altura da janela
	_aCoor[3] := _aCoor[5] / 2
	_aCoor[4] := _aCoor[6] / 2

	_a1 := {_aCoor[1],_aCoor[2],_aCoor[3],_aCoor[4],3,3}
	_a2 := { {45,12,.F.,.F.,.T.}, {200,200,.T.,.T.,.T.} }
	_aObj := MsObjSize(_a1 , _a2 , .T. , .F. )

	_cTab   := "\system\sx3"+SM0->M0_CODIGO+"0.dtc"
	If !File(_cTab)
		MsgAlert("Arquivo invalido " + _cTab)
		Return
	EndIf

	If Select(_cAlTab) > 0
		(_cAlTab)->(dbCloseArea())
	EndIf

	If Select(_cAlSIX) > 0
		(_cAlSIX)->(dbCloseArea())
	EndIf

	DbUseArea(.T., _cRDD, _cTab , _cAlTab, .T., .T.)
	dbSelectarea(_cAlTab)

	If !_lAll
		_cFiltSX3 := "SX3->X3_ARQUIVO = '"+SX2->X2_CHAVE+"'"
		SET FILTER TO &(_cFiltSX3)
		_cFixo := _cFiltSX3
	EndIf

	dbGoTop()
	_aStruct := (_cAlTab)->(dbStruct())

	_cTab   := "\system\six"+SM0->M0_CODIGO+"0.dtc"
	If !File(_cTab)
		MsgAlert("Arquivo invalido " + _cTab)
		Return
	EndIf
	DbUseArea(.T., _cRDD, _cTab , _cAlSIX, .T., .T.)
	dbSelectarea(_cAlSIX)
	If !_lAll
		_cFiltSIX := "SIX->INDICE = '"+SX2->X2_CHAVE+"'"
		SET FILTER TO &(_cFiltSIX)
	EndIf

	DEFINE MSDIALOG _tela TITLE "Campos SX3 - " + SX2->X2_CHAVE + " - " + SX2->X2_NOME FROM 000, 000  TO _aCoor[6],_aCoor[5] COLORS 0, 16777215 PIXEL

	@ _aObj[2,1],_aObj[2,2] FOLDER oFolder SIZE _aObj[2,3],_aObj[2,4] OF _tela ITEMS "Campos","Indices" COLORS 0, 14215660 PIXEL

	oFolder:bSetOption := {|nPasta| Iif(nPasta=1, ;
	(_cAlTab := "SX3", _cFixo := _cFiltSX3, _cFTab := "Campo SX3", _oFTab:Refresh()), ;
	( _cAlTab := "SIX", _cFixo := _cFiltSIX, _cFTab := "Campo SIX", _oFTab:Refresh()) ) }
	
	_cFTab := "Campo SX3"
	_nCol := _aObj[1,2]
	@ _aObj[1,1],_nCol SAY _oFTab Prompt _cFTab OF _tela PIXEL
	_nCol += 35
	@ _aObj[1,1],_nCol MsGet oCampo Var cCampo Size _aObj[1,3],_aObj[1,4] PIXEL HASBUTTON OF _tela
	_nCol += 50
	@ _aObj[1,1],_nCol MsGet oValor Var cValor Size 100,_aObj[1,4] PIXEL HASBUTTON OF _tela
	oValor:cToolTip := "Para pesquisar mais de um resultado por vez utilize separado por virgula ex.: CLI,VEN"
	_nCol += 105
	@ _aObj[1,1],_nCol Button oBusca Prompt "Buscar" Action(fRunFilt(_cAlTab, cCampo, cValor, _cFixo,oValor,oBrow)) Size 40,_aObj[1,4] PIXEL OF _tela

	oBrow := MsBrGetDBase():New( _aObj[2,1],_aObj[2,2],_aObj[2,3],_aObj[2,4],,,, oFolder:aDialogs[1],,,,,,,,,,,, .F., _cAlTab, .T.,, .F.,,, )

	oBrwSIX := MsBrGetDBase():New( _aObj[2,1],_aObj[2,2],_aObj[2,3],_aObj[2,4],,,, oFolder:aDialogs[2],,,,,,,,,,,, .F., _cAlSIX, .T.,, .F.,,, )
	
	For _nx:= 1 to Len(_aStruct)
		If aScan(_aCampos, _aStruct[_nx,01]) > 0
			oBrow:AddColumn( TCColumn():New( _aStruct[_nx,01]   , &("{ || "+_cAlTab+"->"+_aStruct[_nx,01]+" }")  ,,,,,.F.) )
		EndIf
	Next

	_aStruct := (_cAlSIX)->(dbStruct())
	For _nx:= 1 to Len(_aStruct)
		oBrwSIX:AddColumn( TCColumn():New( _aStruct[_nx,01]   , &("{ || "+_cAlSIX+"->"+_aStruct[_nx,01]+" }")  ,,,,,.F.) )
	Next

	oBrow:Align   := CONTROL_ALIGN_ALLCLIENT
	oBrwSIX:Align := CONTROL_ALIGN_ALLCLIENT

	oBrow:Refresh()
	oBrwSIX:Refresh()
	oValor:SetFocus()
	ACTIVATE MSDIALOG _tela CENTERED

	(_cAlTab)->(dbCloseArea())
	(_cAlSIX)->(dbCloseArea())
Return

Static Function fRunFilt(_cAlTab, cCampo, cValor, _cFixo,oValor,oBrow)
	FWMsgRun( /* Obj_tela */ , {|oSay| fFiltar(_cAlTab, cCampo, cValor, _cFixo,oValor,oBrow) } , "Filtrando" , "Filtrando " + _cAlTab )
Return

Static Function fFiltar(_cAlTab, cCampo, cValor, _cFixo,oValor,oBrow)
	Local _aStruct := {}
	Local _cFiltro := ""
	Local _nz := 0
	Local _nCmp := 0
	Local _cTipo := "C"

	Default _cFixo := ""

	dbSelectArea(_cAlTab)
	_aStruct := dbStruct()

	_nCmp := aScan(_aStruct, {|x,y| Upper(AllTrim(cCampo)) = x[1] } )
	If _nCmp = 0
		MsgALert(cCampo + " não encontrado na estrutura da tabela " + _cAlTab)
		oValor:SetFocus()
		Return
	EndIf

	If !Empty(cCampo) .and. !Empty(cValor)
		If !Empty(_cFixo)
			_cFixo := "("+_cFixo + ")" + " .AND. "
		EndIf
		_aVal := Strtokarr2( cValor, ",", .F.)
		
		_cTipo := _aStruct[_nCmp, 2]

		If Len(_aVal) > 0
			If _cTipo $ "C"
				_cFiltro := _cFixo + "('" + Upper(AllTrim(_aVal[1])) +"' $ Upper(" + AllTrim(cCampo) + ")"
				For _nz:= 2 to Len(_aVal)
					_cFiltro += " .OR. '" + Upper(AllTrim(_aVal[_nz])) +"' $ Upper(" + AllTrim(cCampo) + ")"
				Next
			ElseIf _cTipo $ "N"
				_cFiltro := _cFixo + "(" + AllTrim(cCampo) + " == " + Upper(AllTrim(_aVal[1]))
				For _nz:= 2 to Len(_aVal)
					_cFiltro += " .OR. " + AllTrim(cCampo) + " == " + Upper(AllTrim(_aVal[1]))
				Next
			EndIf
			_cFiltro += ")"
		EndIf
		
		Set Filter to &(_cFiltro)
		oBrow:SetFocus()
	ElseIf !Empty(_cFixo)
		Set Filter to &(_cFixo)
		oBrow:SetFocus()
	Else
		Set Filter to
		oBrow:SetFocus()
	EndIf

	(_cAlTab)->(dbGoTop())

Return nil

/*/
@author: caiocrol
@data: 30/10/2015
@descricao: 
/*/
Static Function fIniApp()
Return nil
