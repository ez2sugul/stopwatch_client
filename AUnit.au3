

Local $hFile = FileOpen(@ScriptFullPath)
Local $sLine = ""
Local $aTest[1] ; unitest rsults will be stored
$aTest[0] = 0
Local $aFuction[1] ; functions that should be tested will be stored
$aFuction[0] = 0

While 1
	Local $sLine = FileReadLine($hFile)
	If @error = -1 Then
		ExitLoop
	EndIf

	Local $aMatch = StringRegExp($sLine, '(?i)func ((?i)test.*())', 1)
	If @error = 0 Then
		; resize array
		ReDim $aFuction[UBound($aFuction) + 1]
		; add function name at end of array
		$aFuction[UBound($aFuction) - 1] = $aMatch[0]
		$aFuction[0] += 1

		ReDim $aTest[UBound($aTest) + 1]
		$aTest[UBound($aTest) - 1] = False
		$aTest[0] += 1
	EndIf
	#comments-start
		If StringInStr($sLine, "func", 2, 1, 1, 5) Then
		If StringInStr($sLine, "test", 2, 1, 5, 11) Then
		; resize array
		ReDim $aFuction[UBound($aFuction) + 1]
		; add function name at end of array
		$aFuction[UBound($aFuction) - 1] = $sLine
		$aFuction[0] += 1
		EndIf
		EndIf
	#comments-end
WEnd

For $i = 1 To $aFuction[0]
	$aTest[$i] = Execute($aFuction[$i])
Next

ConsoleWrite("Test Result" & @CRLF)
For $i = 1 To $aTest[0]
	If $aTest[$i] = False Then
		ConsoleWrite($aFuction[$i] & " failed" & @CRLF)
	EndIf
Next

#comments-start
For $i = 1 To $aFuction[0]
	ConsoleWrite($aFuction[$i] & @CRLF)
	Local $aMatch = StringRegExp($aFuction[$i], '((?i)test.*())', 1)

	For $match In $aMatch
		ConsoleWrite($match & @CRLF)
	Next
Next

#comments-end

Func UTAssert(Const $bool, Const $msg = "Assert Failure", Const $erl = @ScriptLineNumber)
    If NOT $bool Then
        ConsoleWrite("(" & $erl & ") := " & $msg & @LF)
    EndIf

    Return $bool
EndFunc