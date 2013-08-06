#include "HTTP.au3"

Local $host = "http://10.200.207.131:8080/imageUpload"
Local $page = "imageUpload"

$socket = _HTTPConnect($host, "8080")

Local $result = _HTTPPost_File($host, $page, $socket, "img/Chrysanthemum.bmp", "")
Local $recv = _HTTPRead($socket, 1)

ConsoleWrite($recv[4] & @CRLF)

ConsoleWrite($result & @CRLF)

Func _HTTPPost_File($host, $page, $socket = -1, $file = "", $fieldname = "")
    Dim $command
	Local $contenttype = ""

    If $socket == -1 Then
        If $_HTTPLastSocket == -1 Then
            SetError(1)
            Return
        EndIf
        $socket = $_HTTPLastSocket
    EndIf

; Maybe this can be done easier/better?
    $boundary = "------"&Chr(Random(Asc("A"), Asc("Z"), 3))&Chr(Random(Asc("a"), Asc("z"), 3))&Chr(Random(Asc("A"), Asc("Z"), 3))&Chr(Random(Asc("a"), Asc("z"), 3))&Random(1, 9, 1)&Random(1, 9, 1)&Random(1, 9, 1)

    If $contenttype = "text/plain" Then
        $fileopen = FileOpen($file, 0); Open in read only mode
        $fileread = FileRead($fileopen)
        FileClose($fileopen)

        $extra_commands = "--"&$boundary&@CRLF
        $extra_commands &= "Content-Disposition: form-data; capturedImageFile=""" & $file & """; name=""capturedImageFile""; filename=""" & $file & """" &@CRLF
        $extra_commands &= "Content-Type: "&$contenttype&@CRLF&@CRLF
        $extra_commands &= $fileread&@CRLF
        $extra_commands &= "--"&$boundary&"--"
    EndIf

    Dim $datasize = StringLen($extra_commands)

    $command = "POST "&$page&" HTTP/1.1"&@CRLF
    $command &= "Host: " &$host&@CRLF
    $command &= "User-Agent: "&$_HTTPUserAgent&@CRLF
    $command &= "Connection: close"&@CRLF
    $command &= "Content-Type: multipart/form-data; boundary="&$boundary&@CRLF
    $command &= "Content-Length: "&$datasize&@CRLF&@CRLF
    $command &= $extra_commands

    Dim $bytessent = TCPSend($socket, $command)

    If $bytessent == 0 Then
        SetExtended(@error)
        SetError(2)
        return 0
    EndIf

    SetError(0)
    Return $bytessent
EndFunc