#include "HttpRequest.au3"
#include <Date.au3>

#include "WinHttp.au3"


$oMyError = ObjEvent("AutoIt.Error", "MyErrFunc") ; Initialize a COM error handler

Local $host = "http://10.200.207.131:8080/imageUpload"
;Local $result = UploadFile($host, @ScriptDir & "\img\" & "Chrysanthemum.bmp")
;Local $result = UploadFileUsingWinHttp(@ScriptDir & "\img\" & "Chrysanthemum.bmp")
Local $result = UploadFileUsingCurl($host, @ScriptDir & "\" & "vanish2.bmp")

ConsoleWrite($result & @CRLF)

Func Main()
	Local $host = "http://172.19.106.209:80/insert"
	Local $query[7] = ["deviceName"]
	Local $http
	Local $result = HttpRequest("POST", $host, $query, $http)

	ConsoleWrite("Result = " & $result & @CRLF)
EndFunc   ;==>Main

Func UploadFile($sUrl, $sFilePath)


	Local $pathArray = StringSplit($sFilePath, "/\")
	Local $sFileName = $pathArray[UBound($pathArray) - 1]


	$boundary = "------" & _TimeToTicks(@HOUR, @MIN, @SEC)


	Local $userAgent = "AutoIt"

	#comments-start
		Content-Type:multipart/form-data; boundary=----WebKitFormBoundaryQjmxvvnRwf2kmIMG
		Origin:null
		User-Agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.71 Safari/537.36
		Request Payload
		------WebKitFormBoundaryQjmxvvnRwf2kmIMG
		Content-Disposition: form-data; name="capturedImageFile"; filename="capture_20130723-073104.384_0.bmp"
		Content-Type: image/bmp


		------WebKitFormBoundaryQjmxvvnRwf2kmIMG--
	#comments-end

	;ConsoleWrite($boundary & @CRLF)
	;ConsoleWrite($userAgent & @CRLF)
	;ConsoleWrite($contentType & @CRLF)
	;ConsoleWrite($contentDisposition & @CRLF)

	Local $contentDisposition = "form-data; name=""capturedImageFile""; filename=""" & $sFileName & '"'
	Local $contentType = "multipart/form-data"
	Local $origin = "null"
	$http = ObjCreate("winhttp.winhttprequest.5.1")
	$http.Open("POST", $sUrl, False)
	;	$http.SetRequestHeader("Host", $sHost)
	;$http.SetRequestHeader("User-Agent", $userAgent)
	;$http.SetRequestHeader("Content-Disposition", $contentDisposition)
	$http.SetRequestHeader("Content-Type", $contentType & "; boundary=" & $boundary)
	;$http.SetRequestHeader("Origin", $origin)
	;$http.SetRequestHeader("Connection", "close")

	Local $hFile = FileOpen($sFileName, 16)
	Local $postData = @CRLF & @CRLF & $boundary & @CRLF
	$postData &= 'Content-Disposition: form-data; capturedImageFile="capturedImageFile"; name="capturedImageFile"; filename="' & $sFileName & '"' & @CRLF
	$postData &= "Content-Type: image/bmp;" & @CRLF
	$postData &= @CRLF & FileRead($hFile) & @CRLF
	$postData &= $boundary & "--"

	$http.Send($postData)

	FileClose($hFile)

	ConsoleWrite($postData & @CRLF)

	If @error = 1 Then
		ConsoleWrite(@error & @CRLF)
		Return -1
	EndIf

	ConsoleWrite("Body" & @CRLF & $http.ResponseText & @CRLF)

	Return 0

EndFunc   ;==>UploadFile

Func UploadFileUsingWinHttp($sFile)

	Global Const $fTestMode = True ; testmode will delete images after 15 minutes
	;Global Const $sAPIKey = "519acd4be68445997245348820" ; testkey, images will always be deleted after 15 minutes
	Global Const $sAPIURL = "/imageUpload"
	Global Const $sUrl = "10.200.207.131:8080"

	Global $hOpen = _WinHttpOpen("AutoIt UploadScreenShot Demo v1")
	Global $hConnect = _WinHttpConnect($hOpen, $sUrl)
	Global $hRequest = _WinHttpOpenRequest($hConnect, "POST", $sAPIURL)

	Global $sData = ""


	$sData &= '----------darker' & @CRLF
	$sData &= 'Content-Disposition: form-data; name="capturedImageFile"; filename="' & $sFile & '"' & @CRLF
	$sData &= 'Content-Type: image/bmp' & @CRLF & @CRLF
	Local $hFile = FileOpen($sFile)
	$sData &= FileRead($hFile) & @CRLF ;~ $sData &= _Base64Encode(FileRead("C:UsersLykerDesktopOtherUntitled-1.png")) & @CRLF
	FileClose($hFile)
	$sData &= '----------darker--'

	Local $result = _WinHttpSendRequest($hRequest, "Content-Type: multipart/form-data; boundary=--------darker", Binary($sData))

	If @error Then
		ConsoleWrite("_WinHttpSendRequest error" & @CRLF)
		ConsoleWrite("_WinHttpSendRequest " & $result & @CRLF)
	EndIf


	_WinHttpReceiveResponse($hRequest)

	$sResult = _WinHttpReadData($hRequest)
	;MsgBox(0, "", $sResult)
	ConsoleWrite("Result : " & $sResult & @CRLF)

	_WinHttpCloseHandle($hRequest)
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)
EndFunc   ;==>UploadFileUsingWinHttp

Func UploadFileUsingCurl($sUrl, $sFile)
	Local $pid = Run(@ScriptDir & '\curl-7.31.0-ssl-sspi-zlib-static-bin-w32\curl.exe -F capturedImageFile=@' & $sFile & ' ' & $sUrl, "", @SW_MAXIMIZE, 8)

	If @error Then
		ConsoleWrite("Error " & @error)
	EndIf

	ConsoleWrite(StdoutRead($pid) & @CRLF)
	ConsoleWrite(StderrRead($pid) & @CRLF)
	ConsoleWrite("PID " & $pid & @CRLF)

EndFunc

; This is my custom defined error handler
Func MyErrFunc($oMyError)
	ConsoleWrite("err.description is: " & @TAB & $oMyError.description & @CRLF & _
			"err.scriptline is: " & @TAB & $oMyError.scriptline & @CRLF & _
			"err.source is: " & @TAB & $oMyError.source & @CRLF)
EndFunc   ;==>MyErrFunc