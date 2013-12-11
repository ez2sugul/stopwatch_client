#include "AssocArrays.au3"
#include "ImageSearch.au3"
#include "DbConn.au3"
#include <ScreenCapture.au3>
#include "HttpRequest.au3"
#include <File.au3>

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

	Local $apps = _get_apps_to_go($env)
	Local $nActivate = WinActivate(AssocArrayGet($env, "app.detecting.on"), "")
	Local $iteration = 0
	Local $primeStartTime = TimerInit()
	Local $nNotFound = 0

	_terminateApp($env)

	While 1
		; count iteration
		; if there is no iteration to go then exit
		If _remainedIteration($env, $iteration) = 0 Then
			Exit
		EndIf

		For $one In $apps
			_Log($one)

			If _start_app($env, $hConn, $primeStartTime, $one) = 0 Then
				; check failed
				$nNotFound += 1
				_Log("Not found count " & $nNotFound)
			Else
				$nNotFound = 0
				_clearMemory($env, $one)
				Sleep(AssocArrayGet($env, "app.interval.sec"))
			EndIf
		Next

		Local $bSwipe = AssocArrayGet($env, "app.swipe")

		If @error Then
			_Log("app.swipe not found")
		Else
			If $bSwipe = 1 Then
				_slideScreen($env, 1)
			EndIf
		EndIf

		If $nNotFound > (UBound($apps) * 2) Then
			; coundn't find any apps
			; connection might be lost
			$nNotFound = 0
			_reconnect($env)
		Else

		EndIf

		$iteration += 1
		_Log("Iteration [" & $iteration & "]")

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

	Local $os = AssocArrayGet($env, "app.target.os")
	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)
	Local $imgPath = @ScriptDir & AssocArrayGet($env, "app.img.path")

	If StringInStr($os, "android") > 0 Then
		_clickImage($imgPath & "\" & "device" & "\" & "reconnect_mobizen.png", 80, "left", 1, $aRect)
		Sleep(1000 * 30)
		Send("{HOME}")
		Send("{HOME}")
		Sleep(1500)
		Send("{HOME}")
		_clickImage($imgPath & "\" & "device" & "\" & "screen_lock.png", 80, "left", 1, $aRect)
		_clickImage($imgPath & "\" & "device" & "\" & "screen_lock_hover.png", 80, "left", 1, $aRect)
		Sleep(1000)
	ElseIf StringInStr($os, "ios") > 0 Then
		MouseClick("right", $aRect[0] + 100, $aRect[1] + 100)
		_Log("_reconnect right")
		Sleep(2000)
		Local $imgArray[2]
		$imgArray[0] = "ios_slide_to_open_start.png"
		$imgArray[1] = "ios_slide_to_open_end.png"
		dragImage($env, $imgArray)

		iosHomeScreen($env)
	EndIf
EndFunc   ;==>_reconnect

; go to home screen of iPhone
Func iosHomeScreen($env)
	Local $os = AssocArrayGet($env, "app.target.os")
	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)
	Local $imgPath = @ScriptDir & AssocArrayGet($env, "app.img.path")
	Local $pivot = "ios_pivot.png"
	Local $searchScreen = "ios_search_screen.png"
	Local $x, $y, $startTime, $endTime
	MouseClick("right", $aRect[0] + 100, $aRect[1] + 100)
	Sleep(1000)

	While _WaitForImageSearchWithoutSleep($imgPath & "/" & "device" & "/" & $pivot, 2000, $aRect, $x, $y, 20, $startTime, $endTime) = 0
		MouseClick("right", $aRect[0] + 100, $aRect[1] + 100)
	WEnd

	If _WaitForImageSearchWithoutSleep($imgPath & "/" & "device" & "/" & $searchScreen, 3000, $aRect, $x, $y, 20, $startTime, $endTime, 0) = 1 Then
		MouseClick("right", $aRect[0] + 100, $aRect[1] + 100)
	EndIf

	Sleep(2000)
EndFunc   ;==>iosHomeScreen


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

	Do
		$result = _ImageSearchArea($findImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, $HBMP)

		;$result=_ImageSearch($findImage,$resultPosition,$x, $y,$tolerance,$HBMP)
		$endTime = TimerDiff($startTime)

		If $result > 0 Then

			Return 1
		EndIf

	Until $endTime > $waitSecs

	Return 0
EndFunc   ;==>_WaitForImageSearchWithoutSleep

Func _WaitForImagesSearchWithoutSleep($findImage, $waitSecs, $aRect, ByRef $x, ByRef $y, $tolerance, ByRef $startTime, ByRef $endTime, $HBMP = 0)
	$startTime = TimerInit()
	$endTime = TimerDiff($startTime)

	Do
		For $i = 1 To $findImage[0]
			$result = _ImageSearchArea($findImage[$i], 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, $HBMP)
			$endTime = TimerDiff($startTime)
			If $result > 0 Then
				Return $i
			EndIf
		Next
	Until $endTime > $waitSecs

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
	Local $aIcon = StringSplit($appIcon, ":")
	Local $appIcon = $aIcon[1]
	Local $appIconTolerance = $aIcon[2]
	Local $startTime
	Local $endTime = -1
	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)
	Local $imgPath = @ScriptDir & AssocArrayGet($env, "app.img.path")
	Local $bUpdateServer = AssocArrayGet($env, "app.web.update")
	Local $os = AssocArrayGet($env, "app.target.os")

	; database fields
	Local $aFields[9] = ["serviceName", "deviceName", "actionName", "actionDate", "startTime", "durationTime", "isError", "network", ""]
	Local $aValues[UBound($aFields)] = [$app_key, AssocArrayGet($env, "app.target.device"), "", @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC, "", "", "", "", ""]

	If StringInStr($os, "android", 0) > 0 Then
		; android only
		; tap on apps image
		_clickImage($imgPath & "\" & "device" & "\" & "apps.png", 80, "left", 500, $aRect)
		Sleep(1000)
	EndIf

	Local $result = _clickImage($imgPath & "\" & $app_key & "\" & $appIcon, $appIconTolerance, "left", 500, $aRect)

	If $result = 0 Then
		; can not find app icon
		Return 0
	EndIf

	Select
		Case $app_type == "simple"
			Local $image = AssocArrayGet($props, "app.loading.done")
			Local $aImage = StringSplit($image, ":")
			Local $image = $aImage[1]
			Local $tolerance = $aImage[2]
			$result = _detectImage($env, $props, $app_key, $imgPath & "\" & $app_key & "\" & $image, $tolerance, $aRect, 15000, $startTime, $endTime)
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
			Local $aVanish = StringSplit($vanishingImage, ":")
			Local $vanishingImage = $aVanish[1]
			Local $vanishTolerance = $aVanish[2]
			Local $expectedImage = AssocArrayGet($props, "app.loading.done")
			Local $aExpected = StringSplit($expectedImage, ":")
			Local $expectedImage = $aExpected[1]
			Local $expectedTolerance = $aExpected[2]
			$result = _detectImageVanishing($env, $props, $app_key, $imgPath & "\" & $app_key & "\" & $vanishingImage, $vanishTolerance, $imgPath & "\" & $app_key & "\" & $expectedImage, $expectedTolerance, $aRect, 15000, $startTime, $endTime)
			$aValues[2] = $vanishingImage
			$aValues[4] = Ceiling(TimerDiff($primeStartTime))
			$aValues[5] = Ceiling($endTime)
			If $result = 1 Then
				$aValues[6] = '0'
			Else
				$aValues[6] = '1'
			EndIf
	EndSelect

	Local $network = "lte"
	$aValues[7] = $network

	_Log($app_key & " " & $app_type & " " & $result & " " & $endTime & " " & $network)

	Local $capturePath = AssocArrayGet($env, "app.capture.path") & "\" & @YEAR & @MON & @MDAY & "\" & $app_key
	Local $hostString = AssocArrayGet($env, "app.web.host")
	Local $hosts = StringSplit($hostString, ",")

	Local $query[UBound($aFields) - 1]
	For $i = 0 To UBound($aFields) - 2
		$query[$i] = $aFields[$i] & "=" & UrlEncode($aValues[$i])
	Next

	Local $requestResult
	If $bUpdateServer = 1 Then
		$requestResult = RequestToServer($hosts, $query)
	EndIf
	Local $sCaptureFileName = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC

	If StringIsDigit($requestResult) = 1 Then
		; inserting record success.
		$sCaptureFileName &= "_" & $requestResult
	EndIf

	_CaptureWindow("", $capturePath, $sCaptureFileName & ".bmp")
	Local $sUploadFile = $capturePath & "\" & $sCaptureFileName & ".bmp"

	If $aValues[6] = 1 And StringIsDigit($requestResult) And FileExists($sUploadFile) Then
		; app loading error occured.
		Local $sUploadUrl = AssocArrayGet($env, "app.web.upload")
		If $bUpdateServer = 1 Then
			UploadFileUsingCurl($sUploadUrl, $sUploadFile)
		EndIf
		_Log("Uploading done " & $sUploadFile)
	EndIf

	Local $bOutput = AssocArrayGet($env, "app.output")

	If @error Then
		_Log("app.output not found")
	Else
		If $bOutput = 1 Then
			Local $sOutputPath = AssocArrayGet($env, "app.output.path")

			If @error Then
				_Log("app.output.path not found")
			Else
				_FileWriteLog(@ScriptDir & "\" & $app_key & ".txt", $aValues[5], -1) ; Write to the logfile passing the filehandle returned by FileOpen.
			EndIf
		Else
			_Log("skip output")
		EndIf
	EndIf

	_terminateApp($env)

	Return 1
EndFunc   ;==>_start_app

Func _areThereAnyEventWindows($env, $props, $app_key)
	Local $eventString = AssocArrayGet($props, "app.event")

	If @error Then
		Return -1
	EndIf

	Local $imagePath = AssocArrayGet($env, "app.img.path")
	Local $hWnd = WinGetHandle(AssocArrayGet($env, "app.detecting.on"))
	Local $aRect = WinGetPos($hWnd)

	Local $aEvent = StringSplit($eventString, ",")
	For $i = 1 To $aEvent[0]
		Local $aAction = StringSplit($aEvent[$i], ":")
		Local $target = $aAction[1]
		Local $tolerance = $aAction[2]
		Local $action = $aAction[3]
		Local $delay = $aAction[4]

		If $action = "click" Then
			If _clickImage(@ScriptDir & $imagePath & "\" & $app_key & "\" & $target, $tolerance, "left", 0, $aRect) Then
				; sleep to wait for screen transition
				; 0 millisecond can be assigned as minimum
				Sleep($delay)
			EndIf
		EndIf
	Next

	Return 0
EndFunc   ;==>_areThereAnyEventWindows

Func RequestToServer($hosts, $query)

	Local $queryString = ""
	Local $http
	Local $host
	Local $i = 0
	Local $requestResult = ""

	For $i = 1 To $hosts[0]
		Local $result = HttpRequest("POST", $hosts[$i], $query, $http)

		If $result = 0 Then
			If $http.Status > 200 Then
				_Log($http.Status)
			EndIf

			$requestResult = StringReplace($http.ResponseText, '"', "")
			$http = 0
		Else
			_Log("Post Method failed")
		EndIf
	Next

	Return $requestResult

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


	Local $result = _WaitForImagesSearchWithoutSleep($imgArray, 5000, $aRect, $x, $y, $tolerance, $startTime, $endTime, 0)

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

	_clickImage(@ScriptDir & AssocArrayGet($env, "app.img.path") & "/device/" & "sms.png", 80, "left", 1, $aRect)
	Sleep(1000)
	_clickImage(@ScriptDir & AssocArrayGet($env, "app.img.path") & "/device/" & "write_sms.png", 80, "left", 1, $aRect)
	Sleep(100)
	Send("01020119386")
EndFunc   ;==>_noticeOperator

Func _clickImage($image, $tolerance, $method, $waitSecs, $aRect)
	Local $result
	Local $startTime
	Local $endTime
	Local $x = 0
	Local $y = 0

	$result = _WaitForImageSearchWithoutSleep($image, $waitSecs, $aRect, $x, $y, $tolerance, $startTime, $endTime, 0)

	If $result = 1 Then
		MouseClick($method, $x, $y, 1, 3)
		Return 1
	EndIf

	Return 0
EndFunc   ;==>_clickImage

Func _mouseMove($image, $waitSecs, $aRect)
	Local $result
	Local $startTime
	Local $endTime
	Local $tolerance = 80
	Local $x = 0
	Local $y = 0

	$result = _WaitForImageSearchWithoutSleep($image, $waitSecs, $aRect, $x, $y, $tolerance, $startTime, $endTime, 0)

	If $result = 1 Then
		MouseMove($x, $y)
		Return 1
	EndIf

	Return 0
EndFunc   ;==>_mouseMove

Func dragImage($env, $imgArray)
	Local $app_detectingOn = AssocArrayGet($env, "app.detecting.on")
	Local $hWnd = WinGetHandle($app_detectingOn)
	Local $aRect = WinGetPos($hWnd)
	Local $x, $y
	Local $startTime, $endTime
	Local $coord[2][2]

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
	MouseClickDrag("left", $coord[0][0], $coord[0][1], $coord[1][0], $coord[1][1], 5)
EndFunc   ;==>dragImage

Func _slideScreen($env, $nDirection)
	_Log("SlideScreen")
	Local $x, $y
	Local $startTime, $endTime
	Local $imgArray[2]
	Local $coord[2][2]
	Local $app_detectingOn = AssocArrayGet($env, "app.detecting.on")
	Local $hWnd = WinGetHandle($app_detectingOn)
	Local $aRect = WinGetPos($hWnd)
	Local $os = AssocArrayGet($env, "app.target.os")

	If StringInStr($os, "android") > 0 Then
		_clickImage(@ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\apps.png", 80, "left", 1, $aRect)
		Sleep(1000)
	ElseIf StringInStr($os, "ios") > 0 Then
		_CaptureWindow("", @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\", "ios_last_screen_temp.png")
	EndIf

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

	If StringInStr($os, "ios") > 0 Then
		Local $lastScreen = "ios_last_screen.png"
		Local $result = _WaitForImageSearchWithoutSleep(@ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "ios_last_screen_temp.png", 5, $aRect, $x, $y, 20, $startTime, $endTime, 0)
		If $result > 0 Then
			MouseClick("right", $aRect[0] + 100, $aRect[1] + 100)
			Sleep(2000)
		EndIf
		Return 0
	EndIf


	Return 0
EndFunc   ;==>_slideScreen

Func _terminateApp($env)
	Local $os = AssocArrayGet($env, "app.target.os")

	If StringInStr($os, "android") > 0 Then
		For $i = 0 To 20
			Send("{ESC}")
			Sleep(200)
		Next

		Send("{HOME}")
		Sleep(700)
	ElseIf StringInStr($os, "ios") > 0 Then
		Local $app_detectingOn = AssocArrayGet($env, "app.detecting.on")
		Local $hWnd = WinGetHandle($app_detectingOn)
		Local $aRect = WinGetPos($hWnd)
		MouseClick("right", $aRect[0] + 100, $aRect[1] + 100)
		Sleep(2000)
	EndIf

EndFunc   ;==>_terminateApp

Func _clearMemory($env, $app)
	Local $trashImg = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "trash.png"
	Local $app_detectingOn = AssocArrayGet($env, "app.detecting.on")
	Local $hWnd = WinGetHandle($app_detectingOn)
	Local $aRect = WinGetPos($hWnd)
	Local $x, $y, $startTime, $endTime
	Local $os = AssocArrayGet($env, "app.target.os")
	Local $appIcon = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\" & $app & "\" & "app_icon.png"
	Local $trashBackground = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "trashBackground.png"
	Local $callTransparent = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "callTransparent.png"

	If StringInStr($os, "android") > 0 Then
		Send("{home down}")
		Sleep(2000)
		Send("{home up}")

		Local $searchResult = _WaitForImageSearchWithoutSleep($trashImg, 500, $aRect, $x, $y, 90, $startTime, $endTime, 0)

		If $searchResult == 1 Then
			MouseMove($x, $y)
			MouseClick("left")
			Sleep(500)
		Else
			Send("{ESC}")
		EndIf
	ElseIf StringInStr($os, "ios") > 0 Then
		MouseClick("right", $aRect[0] + 100, $aRect[1] + 100, 2)
		Sleep(2000)
		Local $searchResult = _WaitForImageSearchWithoutSleep($callTransparent, 3000, $aRect, $x, $y, 20, $startTime, $endTime, 0)
		If $searchResult = 1 Then
			; found background process that should be killed
			MouseMove($x, $y + 80, 3)
			MouseDown("left")
			Sleep(2000)
			MouseUp("left")
			While _WaitForImageSearchWithoutSleep($trashImg, 5000, $aRect, $x, $y, 100, $startTime, $endTime, 0) = 1
				MouseClick("left", $x, $y, 1, 5)
			WEnd
		EndIf

		MouseClick("right", $aRect[0] + 100, $aRect[1] + 100, 1)
		Sleep(500)
		If _WaitForImageSearchWithoutSleep($trashBackground, 3000, $aRect, $x, $y, 20, $startTime, $endTime, 0) = 1 Then
			MouseClick("right", $aRect[0] + 100, $aRect[1] + 100, 1)
			Sleep(500)
		EndIf
	EndIf

EndFunc   ;==>_clearMemory

Func _clearMemory_forVega($env)
	Local $home = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "home.png"
	Local $taskManager = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "task_manager.png"
	Local $trashImg = @ScriptDir & AssocArrayGet($env, "app.img.path") & "\device\" & "trash.png"
	Local $app_detectingOn = AssocArrayGet($env, "app.detecting.on")
	Local $hWnd = WinGetHandle($app_detectingOn)
	Local $aRect = WinGetPos($hWnd)
	Local $x, $y, $startTime, $endTime


	Local $searchResult = _WaitForImageSearchWithoutSleep($taskManager, 3, $aRect, $x, $y, 90, $startTime, $endTime, 0)

	If $searchResult == 1 Then
		MouseMove($x, $y)
		MouseClick("left")
		Sleep(1000)
	Else
		_Log("can not find task manager")
		Send("{ESC}")
	EndIf

	Local $searchResult = _WaitForImageSearchWithoutSleep($trashImg, 3, $aRect, $x, $y, 90, $startTime, $endTime, 0)

	If $searchResult == 1 Then
		MouseMove($x, $y)
		MouseClick("left")
		Sleep(500)
	Else
		_Log("can not find trash")
		Send("{ESC}")
	EndIf

EndFunc   ;==>_clearMemory_forVega


Func _CaptureWindow($sTargetTitle, $sDestRootPath, $sFileName)
	$hWnd = WinGetHandle($sTargetTitle)
	$result = DirCreate($sDestRootPath)

	If $result = 0 Then
		_Log("DirCreate error " & @error)
		Exit
	EndIf

	_ScreenCapture_CaptureWnd($sDestRootPath & "\" & $sFileName, $hWnd, 0, 0, -1, -1, False)
EndFunc   ;==>_CaptureWindow

Func _Timeout($start, $timeout)
	If TimerDiff($start) > $timeout Then
		Return 1
	EndIf

	Return 0
EndFunc   ;==>_Timeout

Func _detectImageVanishing($env, $props, $app_key, $vanishingImage, $vanishTolerance, $expectedImage, $expectedTolerance, $aRect, $timeout, ByRef $startTime, ByRef $endTime)
	Local $result
	Local $tolerance = 70
	Local $x = 0
	Local $y = 0

	$startTime = TimerInit()

	While 1
		_areThereAnyEventWindows($env, $props, $app_key)
		; 사라지는 이미지 탐지
		; timeout 0으로 대기 시간 없이 탐지 실패시 즉시 리턴
		$result = _ImageSearchArea($vanishingImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $vanishTolerance, 0)

		If $result == 1 Then
			; 사라지는 이미지 탐지 성공
			_Log("vanishing image was detected")
			While 1
				$result = _ImageSearchArea($vanishingImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $vanishTolerance, 0)
				If $result == 0 Then
					; 이미지가 사라졌음
					_Log("image was vanished")
					$result = _ImageSearchArea($expectedImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $expectedTolerance, 0)
					If $result = 1 Then
						$endTime = TimerDiff($startTime)
						_Log("Expected Image was found at " & $endTime)
						Return 1
					EndIf
				EndIf

				If _Timeout($startTime, $timeout) == 1 Then
					_Log("vanishing image was not vanished " & $result)
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
			$result = _ImageSearchArea($expectedImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $expectedTolerance, 0)

			If $result = 1 Then
				; 고정적으로 위치한 이미지 탐지 성공
				If $endTime < 0 Then
					; 최초로 탐지한 시간을 저장
					; 사라지는 이미지를 찾지 못한 경우에 로딩 완료 시간으로 사용함
					$endTime = TimerDiff($startTime)
					_Log("Expected Image was found at " & $endTime)
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

Func _detectImage($env, $props, $app_key, $image, $tolerance, $aRect, $timeout, ByRef $startTime, ByRef $endTime)
	Local $x, $y

	$startTime = TimerInit()
	$endTime = TimerDiff($startTime)

	Do
		_areThereAnyEventWindows($env, $props, $app_key)

		$result = _ImageSearchArea($image, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance, 0)
		$endTime = TimerDiff($startTime)

		If $result > 0 Then

			Return 1
		EndIf

	Until $endTime > $timeout

	Return $result
EndFunc   ;==>_detectImage

Func _detectImageBetween($aImage, $aRect, $timeout, ByRef $startTime, ByRef $endTime)
	Local $x, $y
	Local $tolerance = 70


	Local $result = _WaitForImageSearchWithoutSleep($aImage, $timeout, $aRect, $x, $y, $tolerance, $startTime, $endTime, 0)
EndFunc   ;==>_detectImageBetween

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

	If DllStructGetData($tKEYHOOKS, "vkcode") = 121 Then
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