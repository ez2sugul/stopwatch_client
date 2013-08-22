#include "JSMN.au3"
#include "AUnit.au3"
#include "AssocArrays.au3"

Func StartUp()
	Local $sec = IniReadSection(@ScriptDir & "\conf_xml.ini", "okcashbagtouch")
	Local $prop
	AssocArrayCreate($prop, 1)

	For $i = 1 To $sec[0][0]
		AssocArrayAssign($prop, $sec[$i][0], $sec[$i][1])
	Next

	Local $event = AssocArrayGet($prop, "app.event")
	Return $event
EndFunc

Func testAssocArrayGet()
	Local $event = StartUp()

	Return UTAssert($event <> "<senarios>")
EndFunc

Func TestParse()
	Local $event = StartUp()
	Local $Json1 = '{"key":"value","number":100}'
	ConsoleWrite("event : " & $event & @CRLF)
	Local $Data1 = Jsmn_Decode($event)
	Local $aJson = Jsmn_ObjTo2DArray($Data1)

	If Not IsArray($aJson) Then
		Return False
	EndIf

	For $json In $aJson
		ConsoleWrite($aJson[0] & @CRLF)
		ConsoleWrite("json : " & $json & @CRLF)
	Next

	Return True
EndFunc

Func Test3()
	Local $sJson = '{"key":"value", "number":100}'
	Local $oJson = Jsmn_Decode($sJson)
	If Jsmn_IsObject($oJson) Then
		ConsoleWrite("object" & @CRLF)
	Else
		ConsoleWrite("not" & @CRLF)
	EndIf
	;Local $aKey = Jsmn_ObjGetKeys($oJson)
	;For $key In $aKey
	;	ConsoleWrite($key)
	;Next
EndFunc


Func Test4()
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