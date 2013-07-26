#include "AssocArrays.au3"
#include "ImageSearch.au3"
#include "DbConn.au3"
#include <ScreenCapture.au3>
#include "HttpRequest.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Func main()
	_Log("Initializing")
	Global $hHook
	Global $hConn
	_registExitProc()
	OnAutoItExitRegister("Cleanup")
	Opt("WinTitleMatchMode", 2)
	$oMyError = ObjEvent("AutoIt.Error", "MyErrFunc") ; Initialize a COM error handler
	Local $env = _parse_app_section("env")

	Local $sConnectionString = AssocArrayGet($env, "app.db.connection.string")
	Local $sUser = AssocArrayGet($env, "app.db.user")
	Local $sPasswd = AssocArrayGet($env, "app.db.passwd")
	Local $sDbName = AssocArrayGet($env, "app.db.name")
	Local $value = AssocArrayGet($env, "app.db.ip")
	Local $sIP = AssocArrayGet($env, "app.db.ip")
	Local $sTable = AssocArrayGet($env, "app.db.table")


	;	$hConn = _MySQLConnect($sUser, $sPasswd, $sDbName, $sIP, $sConnectionString)

	;	If $hConn = 0 Then
	;		_Log("Connection Failed : " & @error)
	;		Exit
	;	Else
	;		_Query($hConn, GetSQLUseDatabase($sDbName))
	;		_Query($hConn, GetSQLCreateTable($sTable))
	;	EndIf

	Local $apps = _get_apps_to_go($env)
	Local $nActivate = WinActivate(AssocArrayGet($env, "app.detecting.on"), "")
	Local $iteration = 0
	Local $primeStartTime = TimerInit()
	Local $bFoundAny = 0

	While 1
		; count iteration
		; if there is no iteration to go then exit
		If _remainedIteration($env, $iteration) = 0 Then
			Exit
		EndIf

		$bFoundAny = 0

		_terminateApp()

		For $one In $apps
			_Log($one)

			If _start_app($env, $hConn, $primeStartTime, $one) = 0 Then
				; check failed
			Else
				; sleeping to wait for going back to home screen
				_clearMemory($env)
				Sleep(AssocArrayGet($env, "app.interval.sec") * 1000)
				$bFoundAny = 1
			EndIf

			;			Local $dbResult = _Query($hConn, GetErrorCount(AssocArrayGet($env, "app.db.table"), $one, AssocArrayGet($env, "app.target.device")))
		Next

		If $bFoundAny = 0 Then
			; coundn't find any apps
			; connection might be lost
			_reconnect($env)

		Else
			_slideScreen($env, 1)
		EndIf

		$iteration += 1

	WEnd
EndFunc   ;==>main

; This is my custom defined error handler
Func MyErrFunc($oMyError)
	_Log("err.description is: " & @TAB & $oMyError.description & @CRLF & _
			"err.scriptline is: " & @TAB & $oMyError.scriptline & @CRLF & _
			"err.source is: " & @TAB & $oMyError.source)
EndFunc   ;==>MyErrFunc


Func _reconnect($env)
	_Log("trying reconnect")
	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)
	Local $imgPath = @ScriptDir & AssocArrayGet($env, "app.img.path")

	_clickImage($imgPath & "\" & "device" & "\" & "reconnect_mobizen.png", $aRect)
	Sleep(1000 * 30)
	Send("{HOME}")
	Send("{HOME}")
	Sleep(1500)
	Send("{HOME}")
	_clickImage($imgPath & "\" & "device" & "\" & "screen_lock.png", $aRect)
	_clickImage($imgPath & "\" & "device" & "\" & "screen_lock_hover.png", $aRect)
	Sleep(1000)
EndFunc   ;==>_reconnect


Func _remainedIteration($env, $iteration)
	Local $confIteration = AssocArrayGet($env, "app.iteration")

	If $confIteration = -1 Then
		Return 1
	EndIf

	If $confIteration < $iteration Then
		_Log($confIteration & ", " & $iteration)
		Return 0
	EndIf

	Return 1
EndFunc   ;==>_remainedIteration

Func _WaitForImageSearchWithoutSleep($findImage, $waitSecs, $aRect, ByRef $x, ByRef $y, $tolerance, ByRef $startTime, ByRef $endTime, $HBMP = 0)
	$startTime = TimerInit()
	$endTime = TimerDiff($startTime)

	While $endTime < $waitSecs
		$result = _ImageSearchArea($findImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, $HBMP)
		;$result=_ImageSearch($findImage,$resultPosition,$x, $y,$tolerance,$HBMP)
		$endTime = TimerDiff($startTime)

		If $result > 0 Then
			Return 1
		EndIf
	WEnd

	Return 0
EndFunc   ;==>_WaitForImageSearchWithoutSleep

Func _WaitForImagesSearchWithoutSleep($findImage, $waitSecs, $aRect, ByRef $x, ByRef $y, $tolerance, ByRef $startTime, ByRef $endTime, $HBMP = 0)
	$startTime = TimerInit()
	$endTime = TimerDiff($startTime)

	While $endTime < $waitSecs
		For $i = 1 To $findImage[0]
			$result = _ImageSearchArea($findImage[$i], 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, $HBMP)
			$endTime = TimerDiff($startTime)
			If $result > 0 Then
				Return $i
			EndIf
		Next
	WEnd
	Return 0
EndFunc   ;==>_WaitForImagesSearchWithoutSleep

Func _get_apps_to_go($env)
	Local $value = AssocArrayGet($env, "app.list")
	Local $apps = StringSplit($value, ",", 2)
	Return $apps
EndFunc   ;==>_get_apps_to_go


Func _parse_app_section($section)
	Local $sec = IniReadSection(@ScriptDir & "\conf.ini", $section)
	Local $prop
	AssocArrayCreate($prop, 1)

	For $i = 1 To $sec[0][0]
		AssocArrayAssign($prop, $sec[$i][0], $sec[$i][1])
	Next
	Return $prop
EndFunc   ;==>_parse_app_section

Func _start_app($env, $hConn, $primeStartTime, $app_key)
	Local $props = _parse_app_section($app_key)
	Local $app_type = AssocArrayGet($props, "app.define.type")
	Local $appIcon = AssocArrayGet($props, "app.icon")
	Local $startTime
	Local $endTime = -1
	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)
	Local $imgPath = @ScriptDir & AssocArrayGet($env, "app.img.path")

	; database fields
	Local $aFields[9] = ["serviceName", "deviceName", "actionName", "actionDate", "startTime", "durationTime", "isError", "network", ""]
	Local $aValues[UBound($aFields)] = [$app_key, AssocArrayGet($env, "app.target.device"), "", @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC, "", "", "", "", ""]

	; tap on apps image
	_clickImage($imgPath & "\" & "device" & "\" & "apps.png", $aRect)
	Sleep(1000)
	Local $result = _clickImage($imgPath & "\" & $app_key & "\" & $appIcon, $aRect)

	If $result = 0 Then
		; can not find app icon
		Return 0
	EndIf

	Select
		Case $app_type == "simple"
			Local $image = AssocArrayGet($props, "app.loading.done")
			$result = _detectImage($imgPath & "\" & $app_key & "\" & $image, $aRect, 15000, $startTime, $endTime)
			$aValues[2] = $image
			$aValues[4] = Ceiling(TimerDiff($primeStartTime))
			$aValues[5] = Ceiling($endTime)
			If $result = 1 Then
				$aValues[6] = '0'
			Else
				$aValues[6] = '1'
			EndIf

		Case $app_type == "vanish"
			Local $vanishingImage = AssocArrayGet($props, "app.vanish")
			Local $expectedImage = AssocArrayGet($props, "app.loading.done")
			$result = _detectImageVanishing($imgPath & "\" & $app_key & "\" & $vanishingImage, $imgPath & "\" & $app_key & "\" & $expectedImage, $aRect, 15000, $startTime, $endTime)
			$aValues[2] = $vanishingImage
			$aValues[4] = Ceiling(TimerDiff($primeStartTime))
			$aValues[5] = Ceiling($endTime)
			If $result = 1 Then
				$aValues[6] = '0'
			Else
				$aValues[6] = '1'
			EndIf
	EndSelect

	Local $network = _networkStatus($env)
	$aValues[7] = $network

	_Log($app_key & " " & $app_type & " " & $result & " " & $endTime & " " & $network)

	Local $capturePath = AssocArrayGet($env, "app.capture.path") & "\" & @YEAR & @MON & @MDAY & "\" & $app_key
	Local $captureTitle = AssocArrayGet($env, "app.detecting.on")
	Local $dbName = AssocArrayGet($env, "app.db.name")
	Local $tableName = AssocArrayGet($env, "app.db.table")
	_CaptureWindow("", $capturePath, $aValues[6])
	;	Local $nDbResult = _AddRecord($hConn, $dbName & "." & $tableName, $aFields, $aValues)

	Local $hostString = AssocArrayGet($env, "app.web.host")
	Local $hosts = StringSplit($hostString, ",")

	Local $query[UBound($aFields) - 1]
	For $i = 0 To UBound($aFields) - 2
		$query[$i] = $aFields[$i] & "=" & UrlEncode($aValues[$i])
	Next

	Local $requestResult = RequestToServer($hosts, $query)

	_terminateApp()

	Return 1
EndFunc   ;==>_start_app

Func RequestToServer($hosts, $query)

	Local $queryString = ""
	Local $http
	For $host In $hosts
		Local $result = HttpRequest("POST", $host, $query, $http)

		If $result = 0 Then
			If $http.Status > 200 Then
				_Log($http.Status)
			EndIf

			_Log("request result : " & $http.ResponseText)
			;$http = 0
		Else
			_Log("Post Method failed")
		EndIf
	Next

EndFunc   ;==>RequestToServer

Func _networkStatus($env)
	Local $result
	Local $startTime
	Local $endTime
	Local $tolerance = 80
	Local $x = 0
	Local $y = 0
	Local $imgArray[3]

	$imgArray[0] = UBound($imgArray) - 1
	$imgArray[1] = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "lte.png"
	$imgArray[2] = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "3g.png"

	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)


	Local $result = _WaitForImagesSearchWithoutSleep($imgArray, 15000, $aRect, $x, $y, $tolerance, $startTime, $endTime, 0)

	Select
		Case $result == "0"
			Return "unknown"
		Case $result == "1"
			Return "lte"
		Case $result == "2"
			Return "cdma3g"
	EndSelect

	Return "unknown"
EndFunc   ;==>_networkStatus

Func _noticeOperator($env, $wholeCount, $errorCount)
	If @HOUR < 9 And @HOUR > 18 And @WDAY > 1 And @WDAY < 7 Then
		; if current time is not working time, ignore error
		Return
	EndIf

	;	If $wholeCount = 0 Then
	;		ConsoleWrite("was not checked " & @CRLF)
	;	ElseIf $errorCount >= 3 Then
	;		ConsoleWrite("Error Count " & $errorCount & @CRLF)
	;	EndIf

	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)

	_clickImage(@ScriptDir & AssocArrayGet($env, "app.img.path") & "/device/" & "sms.png", $aRect)
	Sleep(1000)
	_clickImage(@ScriptDir & AssocArrayGet($env, "app.img.path") & "/device/" & "write_sms.png", $aRect)
	Sleep(100)
	Send("01020119386")
EndFunc   ;==>_noticeOperator

Func _clickImage($image, $aRect)
	Local $result
	Local $startTime
	Local $endTime
	Local $tolerance = 80
	Local $x = 0
	Local $y = 0

	$result = _WaitForImageSearchWithoutSleep($image, 1, $aRect, $x, $y, $tolerance, $startTime, $endTime, 0)

	If $result = 1 Then
		MouseMove($x, $y)
		MouseClick("left")
		Return 1
	EndIf

	Return 0
EndFunc   ;==>_clickImage

Func _slideScreen($env, $nDirection)
	_Log("SlideScreen")
	Local $x, $y
	Local $startTime, $endTime
	Local $imgArray[2]
	Local $coord[2][2]
	Local $app_detectingOn = AssocArrayGet($env, "app.detecting.on")
	Local $hWnd = WinGetHandle($app_detectingOn)
	Local $aRect = WinGetPos($hWnd)

	_clickImage(@ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\apps.png", $aRect)
	Sleep(1000)

	If $nDirection = 1 Then
		$imgArray[1] = "left_of_the_screen.png"
		$imgArray[0] = "right_of_the_screen.png"
	Else
		$imgArray[0] = "left_of_the_screen.png"
		$imgArray[1] = "right_of_the_screen.png"
	EndIf

	For $i = 0 To UBound($imgArray) - 1
		Local $searchResult = _WaitForImageSearchWithoutSleep(@ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & $imgArray[$i], 5, $aRect, $x, $y, 20, $startTime, $endTime, 0)

		If $searchResult > 0 Then
			Local $tempArr[2] = [$x, $y]
			$coord[$i][0] = $x
			$coord[$i][1] = $y
		Else
			SetError(1)
			Return 1
		EndIf
	Next

	MouseMove($coord[0][0], $coord[0][1])
	MouseClickDrag("left", $coord[0][0], $coord[0][1], $coord[1][0], $coord[1][1], 100)
	Sleep(3000)

	Return 0
EndFunc   ;==>_slideScreen

Func _terminateApp()
	For $i = 0 To 20
		Send("{ESC}")
		Sleep(200)
	Next

	Send("{HOME}")
EndFunc   ;==>_terminateApp

Func _clearMemory($env)
	Local $trashImg = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "trash.png"
	Local $app_detectingOn = AssocArrayGet($env, "app.detecting.on")
	Local $hWnd = WinGetHandle($app_detectingOn)
	Local $aRect = WinGetPos($hWnd)
	Local $x, $y, $startTime, $endTime

	Send("{home down}")
	Sleep(2000)
	Send("{home up}")

	Local $searchResult = _WaitForImageSearchWithoutSleep($trashImg, 3, $aRect, $x, $y, 90, $startTime, $endTime, 0)

	If $searchResult == 1 Then
		MouseMove($x, $y)
		MouseClick("left")
		Sleep(500)
	Else
		Send("{ESC}")
	EndIf

EndFunc   ;==>_clearMemory

Func _CaptureWindow($sTargetTitle, $sDestRootPath, $isError)
	$hWnd = WinGetHandle($sTargetTitle)

	$sNow = @YEAR & @MON & @MDAY & "-" & @HOUR & @MIN & @SEC & "." & @MSEC
	;$sDirName = "C:\Users\sktelecom\Pictures" & "\" & @YEAR & @MON & @MDAY
	$result = DirCreate($sDestRootPath)

	If $result = 0 Then
		_Log("DirCreate error " & @error)
		Exit
	EndIf

	_ScreenCapture_CaptureWnd($sDestRootPath & "\capture_" & $sNow & "_" & $isError & ".bmp", $hWnd)
EndFunc   ;==>_CaptureWindow

Func _Timeout($start, $timeout)
	If TimerDiff($start) > $timeout Then
		Return 1
	EndIf

	Return 0
EndFunc   ;==>_Timeout

Func _detectImageVanishing($vanishingImage, $expectedImage, $aRect, $timeout, ByRef $startTime, ByRef $endTime)
	Local $result
	Local $tolerance = 70
	Local $x = 0
	Local $y = 0

	$startTime = TimerInit()

	While 1
		; 사라지는 이미지 탐지
		; timeout 0으로 대기 시간 없이 탐지 실패시 즉시 리턴
		$result = _ImageSearchArea($vanishingImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, 0)
		;	  ConsoleWrite($vanishingImage & " " & $result & @CRLF)

		If $result == 1 Then
			; 사라지는 이미지 탐지 성공
			_Log("vanishing image was detected")
			While 1
				$result = _ImageSearchArea($vanishingImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, 0)
				If $result == 0 Then
					; 이미지가 사라졌음
					_Log("image was vanished")
					$result = _ImageSearchArea($expectedImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, 0)
					If $result = 1 Then
						_Log("image was detected")
						$endTime = TimerDiff($startTime)
						Return 1
					EndIf
				EndIf

				If _Timeout($startTime, $timeout) == 1 Then
					_Log("Timeout " & $result)
					; if endTime is less than 0, it means any images were not detected.
					; so set endTime as timeout and return 0 as an error
					If $endTime < 0 Then
						$endTime = TimerDiff($startTime)
						Return 0
					EndIf

					Return 1
				EndIf
			WEnd
		ElseIf $result == 0 Then
			; 사라지는 이미지 탐지 실패
			; 고정적으로 위치한 이미지 탐지
			$result = _ImageSearchArea($expectedImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, 0)

			If $result = 1 Then
				; 고정적으로 위치한 이미지 탐지 성공
				If $endTime < 0 Then
					; 최초로 탐지한 시간을 저장
					; 사라지는 이미지를 찾지 못한 경우에 로딩 완료 시간으로 사용함
					$endTime = TimerDiff($startTime)
				EndIf
			EndIf

			If _Timeout($startTime, $timeout) == 1 Then
				_Log("Timeout " & $result)
				; if endTime is less than 0, it means any images were not detected.
				; so set endTime as timeout and return 0 as an error
				If $endTime < 0 Then
					$endTime = TimerDiff($startTime)
					Return 0
				EndIf

				Return 1
			EndIf

		EndIf
	WEnd

	; 사라지는 이미지 탐지 실패
	; 하지만 앱로딩 측정이 실패한 것은 아님
	Return 0

EndFunc   ;==>_detectImageVanishing

Func _detectImage($image, $aRect, $timeout, ByRef $startTime, ByRef $endTime)
	Local $x, $y
	Local $tolerance = 70

	Local $result = _WaitForImageSearchWithoutSleep($image, $timeout, $aRect, $x, $y, $tolerance, $startTime, $endTime, 0)

	;_write_result_to_DB($props, $startTime, $duration)
	Return $result
EndFunc   ;==>_detectImage

main()


Func _Log($line)
	ConsoleWrite("[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $line & @CRLF)
EndFunc   ;==>_Log

Func _ExitProc($nCode, $wParam, $lParam)
	Local $tKEYHOOKS
	$tKEYHOOKS = DllStructCreate($tagKBDLLHOOKSTRUCT, $lParam)

	If $nCode < 0 Then
		Return _WinAPI_CallNextHookEx($hHook, $nCode, $wParam, $lParam)
	EndIf

	;ConsoleWrite("Entered Key = " & DllStructGetData($tKEYHOOKS, "vkcode") & @CRLF)

	If DllStructGetData($tKEYHOOKS, "vkcode") = 123 Then
		Exit
	EndIf
EndFunc   ;==>_ExitProc

Func _registExitProc()
	; global keyboard hooking to exit process while estimating
	Global $hStub_KeyProc = DllCallbackRegister("_ExitProc", "long", "int;wparam;lparam")
	Local $hMod = _WinAPI_GetModuleHandle(0)
	Global $hHook = _WinAPI_SetWindowsHookEx($WH_KEYBOARD_LL, DllCallbackGetPtr($hStub_KeyProc), $hMod)
EndFunc   ;==>_registExitProc


Func ArrayToString(ByRef $arr)
	Local $sResult = ""

	For $i = 0 To UBound($arr) - 1
		If $sResult == "" Then
			$sResult = $arr[$i]
		Else
			If $arr[$i] == "" Then
				$sResult = $sResult
			Else
				$sResult = $sResult & "," & $arr[$i]
			EndIf
		EndIf
	Next

	;$sResult = "[" & $sResult & "]"

	Return $sResult

EndFunc   ;==>ArrayToString

Func Cleanup()
	_WinAPI_UnhookWindowsHookEx($hHook)
	DllCallbackFree($hStub_KeyProc)
	_MySQLEnd($hConn)
EndFunc   ;==>Cleanup