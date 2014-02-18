
Func UTAssert(Const $bool, Const $msg = "Assert Failure", Const $erl = @ScriptLineNumber)
    If NOT $bool Then
        ConsoleWrite("!> Line " & $erl & " := " & $msg & @LF)
    ElseIf $bool Then
		ConsoleWrite("+> Line" & $erl & " := " & $msg & @LF)
	EndIf

    Return $bool
EndFunc