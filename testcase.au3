#include "AssocArrays.au3"
#include "mysql.au3"
#include "ImageSearch.au3"
#include <ScreenCapture.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Func main()
   
   OnAutoItExitRegister("Cleanup")
   Opt("WinTitleMatchMode", 2)
   Local $nActivate = WinActivate("Mobizen", "")
   Local $iteration = 0
   
   Local $props = _parse_app_section("all_apps")
   
   Local $app_type = AssocArrayGet($props, "app.define.type")
   Local $app_detectingOn = AssocArrayGet($props, "app.detecting.on")
   Local $vanishingImage = AssocArrayGet($props, "app.vanish")
   Local $expectedImage = AssocArrayGet($props, "app.loading.done")
   Local $appIcon = AssocArrayGet($props, "app.icon")
   
   Local $hWnd = WinGetHandle($app_detectingOn)
   Local $aRect = WinGetPos($hWnd)
   
   _slideScreen(1, $aRect)
   
EndFunc

Func _parse_app_section($section)
   Local $sec = IniReadSection(@ScriptDir & "\conf.ini", $section)
   Local $prop
   AssocArrayCreate($prop, 1)
   
   For $i = 1 to $sec[0][0]
	  AssocArrayAssign($prop, $sec[$i][0], $sec[$i][1])
   Next
   return $prop
EndFunc

Func _init() 
   Local $props = _parse_app_section($app_key)
   
   Local $app_type = AssocArrayGet($props, "app.define.type")
   Local $app_detectingOn = AssocArrayGet($props, "app.detecting.on")
   Local $vanishingImage = AssocArrayGet($props, "app.vanish")
   Local $expectedImage = AssocArrayGet($props, "app.loading.done")
   Local $appIcon = AssocArrayGet($props, "app.icon")
   
   Local $hWnd = WinGetHandle($app_detectingOn)
   Local $aRect = WinGetPos($hWnd)
   Local $imgPath = @ScriptDir & "\img\" & $app_key
   
EndFunc



Func _WaitForImageSearchWithoutSleep($findImage,$waitSecs,$aRect, ByRef $x, ByRef $y,$tolerance, ByRef $startTime, ByRef $endTime,$HBMP=0)
   $waitSecs = $waitSecs * 1000
   $startTime=TimerInit()
   $endTime = TimerDiff($startTime)

   While $endTime < $waitSecs
	  $result = _ImageSearchArea($findImage, 1, $aRect[0], $aRect[1], $aRect[0] + $aRect[2], $aRect[1] + $aRect[3], $x, $y, $tolerance,$HBMP)
	  ;$result=_ImageSearch($findImage,$resultPosition,$x, $y,$tolerance,$HBMP)
	  $endTime = TimerDiff($startTime)

	  if $result > 0 Then
		return 1
	  EndIf
   WEnd

   return 0
EndFunc

Func _slideScreen($nDirection, $aRect)
	ConsoleWrite("SlideScreen"  & @CRLF)
	Local $x, $y
	Local $startTime, $endTime
	Local $imgArray[2]
	Local $coord[2][2]

	If $nDirection = 1 Then
		$imgArray[1] = "left_of_the_screen.png"
		$imgArray[0] = "right_of_the_screen.png"
	Else
		$imgArray[0] = "left_of_the_screen.png"
		$imgArray[1] = "right_of_the_screen.png"
	EndIf

	For $i = 0 To UBound($imgArray) - 1
		Local $searchResult = _WaitForImageSearchWithoutSleep(@ScriptDir & "\device\" & $imgArray[$i], 5, $aRect, $x, $y, 20, $startTime, $endTime, 0)

		If $searchResult > 0 Then
			Local $tempArr[2] = [$x, $y]
			$coord[$i][0] = $x
			$coord[$i][1] = $y
		Else
			SetError(1)
			return 1
		EndIf
	Next

   ConsoleWrite($coord[0][0] & "," &  $coord[0][1] & "," & $coord[1][0] & "," &$coord[1][1] & @CRLF)
	MouseMove($coord[0][0], $coord[0][1])
	MouseClickDrag("left", $coord[0][0], $coord[0][1], $coord[1][0], $coord[1][1], 100)
	Sleep(3000)

	return 0
EndFunc

main()