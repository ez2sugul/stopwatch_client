#include "SendMail.au3"
;##################################
; Variables
;##################################
$SmtpServer = "smtp.gmail.com"              ; address for the smtp-server to use - REQUIRED
$FromName = "stopwatch.skplanet"                      ; name from who the email was sent
$FromAddress = "stopwatch.skplanet@gmail.com" ; address from where the mail should come
$ToAddress = "seunghoon.baek@sk.com,seunghoon100@gmail.com"   ; destination address of the email - REQUIRED
$Subject = "stopwatch"                   ; subject from the email - can be anything you want it to be
$Body = "stopwatch"                              ; the messagebody from the mail - can be left blank but then you get a blank mail
$AttachFiles = ""                       ; the file(s) you want to attach seperated with a ; (Semicolon) - leave blank if not needed
$CcAddress = ""       ; address for cc - leave blank if not needed
$BccAddress = ""     ; address for bcc - leave blank if not needed
$Importance = ""                  ; Send message priority: "High", "Normal", "Low"
$Username = "stopwatch.skplanet@gmail.com"                    ; username for the account used from where the mail gets sent - REQUIRED
$Password = "rltnfdnjs1"                  ; password for the account used from where the mail gets sent - REQUIRED
$IPPort = 465                            ; port used for sending the mail
$ssl = 1                                ; enables/disables secure socket layer sending - put to 1 if using httpS
;~ $IPPort=465                          ; GMAIL port used for sending the mail
;~ $ssl=1                               ; GMAILenables/disables secure socket layer sending - put to 1 if using httpS


$rc = _INetSmtpMailCom($SmtpServer, $FromName, $FromAddress, $ToAddress, $Subject, $Body, $AttachFiles, $CcAddress, $BccAddress, $Importance, $Username, $Password, $IPPort, $ssl)
If @error Then
    MsgBox(0, "Error sending message", "Error code:" & @error & "  Description:" & $rc)
EndIf


Func Notification($fromMail, $toMail, $subject, $body)
	;curl -X POST -H "Content-Type: application/json" -d '{"from":"byunghun.woo@skvalley.com", "to":["byunghun.woo@sk.com", "jaejinyun@sk.com"],
	;"subject":"notification simpleMailSender xxx test", "text":"ci xxx test content", "html":true}' http://172.19.112.64/notification/simpleMailSender -v
	ConsoleWrite("'ddd'" & @CRLF)
	;Local $curl = @ScriptDir & '\curl-7.31.0-ssl-sspi-zlib-static-bin-w32\curl.exe'
	Local $curl = "C:\Users\skplanet\Downloads\curl_735_0_ssl\curl.exe"
	Local $curlParams = '-g -X POST -H "Content-Type: application/json" -d'
	Local $mailParams = "'" & '{"from":' & $fromMail & ', "to":' & $toMail & ', "subject":' & $subject & ', "text":' & $body & ', "html":true}' & "'"
	Local $nofiServer = 'http://172.19.112.64/notification/simpleMailSender -v'
	ConsoleWrite($curl & " " & $curlParams & " " & $mailParams & " " & $nofiServer & @CRLF)
	Local $pid = Run($curl & " " & $curlParams & " " & $mailParams & " " & $nofiServer, "", @SW_MINIMIZE, 0x10)

	If @error Then
		ConsoleWrite("curl error " & @error)
	EndIf

	Return $pid

EndFunc

;Notification('qna-speed@skvalley.com', '["seunghoon.baek@sk.com","seunghoon100@gmail.com"]', 'stopwatch', 'dd')
