;
; method : post or get
; host : host string of url
; path : path string of url
; query : array of query strings, each query string must be pair of key and value that can be divided by '='.
;		for example key=value
; http : [out] if function success http handle will be stored
Func HttpRequest($method, $host, $path, $query, ByRef $http)
   Local $queryString = ""

   For $str In $query
	  If $queryString = "" Then
		 $queryString = "" & $str
	  Else
		 $queryString = $queryString & "&" & $str
	  EndIf
   Next

   $http = ObjCreate("winhttp.winhttprequest.5.1")

   If @error = 1 Then
	  ConsoleWrite(@error & @CRLF)
	  Return -1
   EndIf

   $http.Open($method, $host & $path, False)
   $http.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")

   $http.Send($queryString)

   Return 0
EndFunc

Func UrlEncode($url)
   Local $encodedUrl = ""
   Local $acode = ""

   For $i = 1 To StringLen($url)
	  $acode = Asc(StringMid($url, $i, 1))
	  Select
	  Case ($acode >= 48 And $acode <= 57) Or ($acode >= 65 And $acode <= 90) Or ($acode >= 97 And $acode <=122)
		 $encodedUrl = $encodedUrl & StringMid($url, $i, 1)
	  Case $acode = 32
		 $encodedUrl = $encodedUrl & "+"
	  Case Else
		 $encodedUrl = $encodedUrl & "%" & Hex($acode, 2)
	  EndSelect
   Next

   Return $encodedUrl
EndFunc