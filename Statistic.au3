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

	Return Round($timeSum / $arr[0], 3)
EndFunc

Func GetPercentile($arr, $percentile)
	Local $count = $arr[0]
	Local $percentileValue = Round($count * $percentile)
	_ArraySortNum($arr, 0, 1)
	;_ArrayDisplay($arr)
	Return Round($arr[$percentileValue], 3)
EndFunc

Func _ArraySortNum(ByRef $n_array, $i_descending = 0, $i_start = 1)
    Local $i_ub = UBound($n_array)
    For $i_count = $i_start To $i_ub - 2
        Local $i_se = $i_count
        If $i_descending Then
            For $x_count = $i_count To $i_ub - 1
                If Number($n_array[$i_se]) < Number($n_array[$x_count]) Then $i_se = $x_count
            Next
        Else
            For $x_count = $i_count To $i_ub - 1
                If Number($n_array[$i_se]) > Number($n_array[$x_count]) Then $i_se = $x_count
            Next
        EndIf
        Local $i_hld = $n_array[$i_count]
        $n_array[$i_count] = $n_array[$i_se]
        $n_array[$i_se] = $i_hld
    Next
EndFunc   ;==>_ArraySortNum

Func testGetArrayFromOutput()
	Local $fileName = "C:\Users\skplanet\Desktop\gifticon.txt"
	Local $arr = GetArrayFromOutput($fileName)

	UTAssert($arr[0] = 382, $arr[0])

	Return True
EndFunc   ;==>testGetArrayFromOutput

Func testGetAverage()
	Local $fileName = "C:\Users\skplanet\Desktop\gifticon.txt"
	Local $arr = GetArrayFromOutput($fileName)
	Local $value = GetAverage($arr)
	UTAssert($value == 2150.228, $value)
EndFunc

Func testGetPercentile()
	Local $fileName = "C:\Users\skplanet\Desktop\gifticon.txt"
	Local $arr = GetArrayFromOutput($fileName)
	Local $value = GetPercentile($arr, 0.9)
	UTAssert($value == 2038.362, $value)
EndFunc

; =====================================================================
; Selftesting part
; =====================================================================
If StringInStr(@ScriptName, "Statistic.au3") Then
	testGetArrayFromOutput()
	testGetAverage()
	testGetPercentile()
EndIf
