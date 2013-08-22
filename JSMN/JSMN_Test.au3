#Include "JSMN.au3"

If Test1() And Test2() And Test3() Then MsgBox(0, "JSMN UDF Test", "All Passed !")
Exit

Func Test1()
	Local $Json1 = FileRead(@ScriptDir & "\test.json")
	Local $Data1 = Jsmn_Decode($Json1)
	Local $Json2 = Jsmn_Encode($Data1)

	Local $Data2 = Jsmn_Decode($Json2)
	Local $Json3 = Jsmn_Encode($Data2)

	;ConsoleWrite("Test1 Result: " & $Json3 & @CRLF)
	Return ($Json2 = $Json3)
EndFunc

Func Test2()
	Local $Json1 = FileRead(@ScriptDir & "\test.json")
	Local $Data1 = Jsmn_Decode($Json1)
	Local $Json2 = Jsmn_Encode($Data1)

	Local $2DArray = Jsmn_ObjTo2DArray($Data1)
	Local $Data2 = Jsmn_ObjFrom2DArray($2DArray)

	Local $Json3 = Jsmn_Encode($Data2)

	;ConsoleWrite("Test2 Result: " & $Json3 & @CRLF)
	Return ($Json2 = $Json3)
EndFunc

Func Test3()
	Local $Json1 = '["100","hello world",{"key":"value","number":100}]'
	Local $Data1 = Jsmn_Decode($Json1)

	Local $Json2 = Jsmn_Encode($Data1, $JSMN_UNQUOTED_STRING)
	Local $Data2 = Jsmn_Decode($Json2)

	Local $Json3 = Jsmn_Encode($Data2, $JSMN_PRETTY_PRINT, "  ", "\n", "\n", ",")
	Local $Data3 = Jsmn_Decode($Json3)

	Local $Json4 = Jsmn_Encode($Data3, $JSMN_STRICT_PRINT)

	ConsoleWrite("Test3 Unquoted Result: " & $Json2 & @CRLF)
	ConsoleWrite("Test3 Pretty Result: " & $Json3 & @CRLF)
	Return ($Json1 = $Json4)
EndFunc
