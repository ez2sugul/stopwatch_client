#include <File.au3>
#include "AUnit.au3"

Func GetArrayFromOutput($outputFile)
	Local $hFile = FileOpen($outputFile)
	Local $sLine = ""
	Local $aTime[1]
	$aTime[0] = UBound($aTime) - 1

	If $hFile == -1 Then
		Return -1
	EndIf



	While True
		$sLine = FileReadLine($hFile)

		If @error = -1 Then
			ExitLoop
		ElseIf @error = 1 Then
			Return -1
		EndIf

		Local $aLine = StringSplit($sLine, " :")
		Local $time = $aLine[UBound($aLine) - 1]
		_ArrayAdd($aTime, $time)
		$aTime[0] = UBound($aTime) - 1

	WEnd

	Return $aTime

EndFunc   ;==>GetArrayFromOutput

Func GetAverage($arr)
	Local $timeSum = 0.0
	For $i = 1 To $arr[0]
		$timeSum += $arr[$i]
	Next

	Return $timeSum / $arr[0]
EndFunc

Func GetPercentile()
EndFunc

Func testGetArrayFromOutput()
	Local $fileName = "C:\Users\skplanet\Desktop\gifticon.txt"
	Local $arr = GetArrayFromOutput($fileName)

	UTAssert($arr[0] = 382, "asd")

	Return True
EndFunc   ;==>testGetArrayFromOutput

Func testGetAverage()
	Local $fileName = "C:\Users\skplanet\Desktop\gifticon.txt"
	Local $arr = GetArrayFromOutput($fileName)
	Local $value = GetAverage($arr)
	UTAssert($value == 2150.22830311183, "asd")
EndFunc

; =====================================================================
; Selftesting part
; =====================================================================
If StringInStr(@ScriptName, "Statistic.au3") Then
	testGetArrayFromOutput()
	testGetAverage()
EndIf
