#cs ----------------------------------------------------------------------------
	
	AutoIt Version: 3.3.0.0
	Author:         David Nuttall "Nutster"
	Date:			December 16, 2007; June 23, 2009
	
	Script Function:
	Associative Array functionality
	
#ce ----------------------------------------------------------------------------

#include-once

#cs
	Functions List:  (read comments on each function for more details)
	AssocArrayCreate:  Create an Associative Array in a variable.  The function put a 2 X n two-dimensional array in the variable.
	AssocArrayVerify:  Verify that an array is storing an associative array.
	AssocArrayAssign:  Assign a value into the associative array.
	AssocArrayGet:  Gets an existing value from the associative array.  Sets @Error = 1 if key not found
	AssocArrayExists:  Determines if a given key exists in the associative array.
	AssocArrayDelete:  Remove a given key from the associative array.
	AssocArrayKeys:  Generates an array of the keys currently in the associative array.
	AssocArraySave:  Save the associative array to a text file.
	AssocArrayLoad:  Load an associative array from a text file.
	
	All functions, except AssocArrayCreate, AssocArrayVeryify and AssocArrayLoad set @Error = 2 if the associative array is not setup properly.
	AssocArrayVerify returns false in this case and AssocArrayCreate and AssocArrayLoad build a new associative array in the given variable.
	
	Support Functions:  (not to be called directly)
	HashPos:  A hash function to determine the location in the array for a given element.
	NotPrime:  Used in resizing the hash table.  Determines if a number is prime (false) or composite (true)
	Rehash_Grow:  Resize the associative array, keeping the old values.
	_UBitShift:  Bit shifting routine used in HashPos.
	StringQuote:  Put quotes around a string, otherwise return a string.  Used in saving array values.
	CVSParse:  A function that takes CVS string and parses it into elements
#ce

Const $gbAA_Debug = False ; Assist in debugging the functions

#cs
	Function:  AssocArrayCreate
	Purpose:  Create an associative array in a variable.
	Parameters:
	$aArray:  The variable to have an associative array create in it.
	$nSize:  The starting size of the new array
	$nGrowth:  The percentage of current size to grow the array when needed.  If 0, no growth happens.  30 = 30% growth each time.
	Return value:  True if the associative array could be created; False otherwise
	Notes:  The variable does not have to be declared as an array first, but should be declared before calling this routine.  Any existing contents of the variable used for the associative array will be lost, even if it contained an associative array already.
#ce
Func AssocArrayCreate(ByRef $aArray, Const $nSize, Const $nGrowth = 50)
	If IsNumber($nSize) = 0 Then
		; Need a number here
		Return False
	ElseIf $nSize < 1 Then
		; Too small
		Return False
	Else
		Local $nHashSize = Ceiling($nSize * 1.33333) + 1 ; Hash table should start about 1/3 larger than expected number of elements

		While NotPrime($nHashSize) ; Hash function usually operates best when a prime number of elements are present
			$nHashSize += 1
		WEnd
		Local $aTmp[2][$nHashSize + 1]
		$aArray = $aTmp
		$aArray[0][0] = 0 ; Active associative array size
	EndIf
	If IsNumber($nGrowth) = 0 Then
		; Need a number here
		Return False
	ElseIf $nGrowth < 0 Then
		; Too small
		$aArray[1][0] = 0
	Else
		$aArray[1][0] = $nGrowth / 100.0
	EndIf
	Return True
EndFunc   ;==>AssocArrayCreate

#cs
	Function:  AssocArrayVerify
	Purpose:  Verify that the given array stores an associative array.
	Parameters:
	$aArray:  The array possibly containing an associative array
	Return value:  True if the variable stores an associative array; False otherwise
	Notes:  This verifies that the array is consistant with the setup from AssocArrayCreate and AssocArrayAssign
#ce
Func AssocArrayVerify(Const ByRef $aArray)
	If UBound($aArray, 0) <> 2 Then
		Return False
	ElseIf Not IsInt($aArray[0][0]) Then
		; Current array size.
		Return False
	ElseIf $aArray[0][0] < 0 Then
		; Not enough elements
		Return False
	ElseIf $aArray[0][0] > UBound($aArray, 2) Then
		; Somehow too many elements
		Return False
	ElseIf Not (IsFloat($aArray[1][0]) Or IsInt($aArray[1][0])) Then
		; Growth rate
		Return False
	ElseIf $aArray[1][0] < 0.0 Then
		; Growth rate not allowed to be negative.
		Return False
	Else
		Return True
	EndIf
EndFunc   ;==>AssocArrayVerify

#cs
	Function:  AssocArrayAssign
	Purpose:  Assign a value to an element of an associative array.
	Parameters:
	$aArray:  The array containing an associative array
	$sKey:  The key value in the array
	$vValue:  The value to assign to the element of the associtive array
	Return value:  True if the value could be assigned; False otherwise
	Notes:  This uses a hash table with open addressing using linear probing.
	There is probably a faster way to resize a hash table than I use here.
	It grows the array if hash key collisions occur more than 3 times in a row or
	hash key collisions push the assignment off the end of the array.
#ce
Func AssocArrayAssign(ByRef $aArray, Const $sKey, Const $vValue)
	Local $nPos
	Local $nCollide = 0

	If AssocArrayVerify($aArray) = False Then
		SetError(2)
		Return False
	EndIf
	$nPos = HashPos($sKey, UBound($aArray, 2) - 1) + 1
	If $gbAA_Debug Then ConsoleWrite("AssocArrayAssign:  UBound = " & UBound($aArray, 2) & ", $nPos = " & $nPos & ", $sKey = " & $sKey & ", $vValue = " & $vValue & @CR)
	; If more than 75% of the array is used and we can actually grow, rehash the array.
	If UBound($aArray, 2) * 0.75 < $aArray[0][0] And $aArray[1][0] > 0.0 Then
		Rehash_Grow($aArray)
	EndIf
	While $nPos < UBound($aArray, 2)
		Switch $aArray[0][$nPos]
			Case ""
				; Not found.  Fill it in
				$aArray[0][$nPos] = $sKey
				$aArray[1][$nPos] = $vValue
				$aArray[0][0] += 1
				If $gbAA_Debug Then ConsoleWrite("AssocArrayAssign:  Used = " & $aArray[0][0] & ", After collisions $nPos = " & $nPos & @CR)
				Return True
			Case $sKey
				; Found the correct key
				$aArray[1][$nPos] = $vValue
				If $gbAA_Debug Then ConsoleWrite("AssocArrayAssign:  Used = " & $aArray[0][0] & ", After collisions $nPos = " & $nPos & @CR)
				Return True
			Case Else
				; Key collision
				$nPos += 1
				$nCollide += 1
				If $nCollide > 3 Then ExitLoop
		EndSwitch
	WEnd
	; Not found, at end of array or too many collisions
	If Rehash_Grow($aArray) Then
		Return AssocArrayAssign($aArray, $sKey, $vValue) ; Assign the value that got us here in the first place
	Else
		; Won't grow.  No place to put the value.
		Return False
	EndIf
EndFunc   ;==>AssocArrayAssign

#cs
	Function:  AssocArrayExists
	Purpose:  Determine if a key exists in an associative array.
	Parameters:
	$aArray:  The array containing an associative array
	$sKey:  The key value in the array
	Return value:  If the key is in the associative array, return True.  Otherwise return False.
	Notes:  This uses a hash table, which is pretty fast.  It could be replaced with another fast search method.
#ce
Func AssocArrayExists(ByRef Const $aArray, Const $sKey)
	Local $nPos = HashPos($sKey, UBound($aArray, 2) - 1) + 1

	If AssocArrayVerify($aArray) = False Then
		SetError(2)
		Return False
	EndIf
	While $nPos < UBound($aArray, 2)
		Switch $aArray[0][$nPos]
			Case ""
				; Not found
				Return False
			Case $sKey
				; Got it
				Return True
			Case Else
				$nPos += 1
		EndSwitch
	WEnd
	; Not found at end of array
	Return False
EndFunc   ;==>AssocArrayExists

#cs
	Function:  AssocArrayGet
	Purpose:  Get the value of an element in an associative array.
	Parameters:
	$aArray:  The array containing an associative array
	$sKey:  The key value in the array
	Return value:  Value in the element if found.  Otherwise, sets @Error to 1
	Notes:  This uses a hash table, which is pretty fast.  It could be replaced with another fast search method.
#ce
Func AssocArrayGet(ByRef Const $aArray, Const $sKey)
	Local $nPos = HashPos($sKey, UBound($aArray, 2) - 1) + 1

	If AssocArrayVerify($aArray) = False Then
		SetError(2)
		Return False
	EndIf
	While $nPos < UBound($aArray, 2)
		Switch $aArray[0][$nPos]
			Case ""
				; Not found
				SetError(1)
				Return False
			Case $sKey
				; Got it
				Return $aArray[1][$nPos]
			Case Else
				$nPos += 1
		EndSwitch
	WEnd
	; Not found at end of array
	SetError(1)
	Return False
EndFunc   ;==>AssocArrayGet

#cs
	Function:  AssocArrayDelete
	Purpose:  Remove an element with a given key from an associative array.
	Parameters:
	$aArray:  The array containing an associative array
	$sKey:  The key value in the array
	Return value:  True if element could be removed.  False if the key was not present.
	Notes:  This uses a hash table, which is pretty fast.  It could be replaced with another fast search method.
#ce
Func AssocArrayDelete(ByRef $aArray, Const $sKey)
	Local $nPos = HashPos($sKey, UBound($aArray, 2) - 1) + 1
	Local $I, $k

	If AssocArrayVerify($aArray) = False Then
		SetError(2)
		Return False
	EndIf
	While $nPos < UBound($aArray, 2)
		Switch $aArray[0][$nPos]
			Case ""
				; Not found
				Return False
			Case $sKey
				; Got it
				ExitLoop
			Case Else
				$nPos += 1
		EndSwitch
	WEnd
	If $nPos < UBound($aArray, 2) Then
		$aArray[0][$nPos] = ""
		; Now to check potential relocated elements, due to prior collisions.  Reset if not in the correct location.
		While $nPos < UBound($aArray, 2)
			If $aArray[0][$nPos] = "" Then
				; End of the search.  Stop.
				ExitLoop
			EndIf
			$I = HashPos($aArray[0][$nPos], UBound($aArray, 2) - 1) + 1
			If $I < $nPos Then
				$I = $aArray[0][$nPos]
				$k = $aArray[1][$nPos]
				$aArray[0][$nPos] = ""
				AssocArrayAssign($aArray, $I, $k)
			EndIf
			$nPos += 1
		WEnd
		Return True
	Else
		Return False
	EndIf
EndFunc   ;==>AssocArrayDelete

#cs
	Function:  AssocArrayKeys
	Purpose:  Generate a list of the keys in an associative array.
	Parameters:
	$aArray:  The array containing an associative array
	Return value:  A one-dimensional array containting the keys.  This list is not necessarily in order.
	If no elements are in the associative array, @Error = 1, and returns false.
	Notes:  This uses a hash table, which is pretty fast.  It could be replaced with another fast search method.
#ce
Func AssocArrayKeys(ByRef Const $aArray)
	Local $nPos = 0, $I
	Local $aRetVal

	If Not AssocArrayVerify($aArray) Then
		SetError(2)
		Return False
	EndIf
	If $aArray[0][0] = 0 Then
		SetError(1)
		Return False
	EndIf

	; Size to the number of assigned elements
	Local $aRetVal[$aArray[0][0]]

	For $I = 1 To UBound($aArray, 2) - 1
		If $aArray[0][$I] > "" Then
			; rem Be ready to resize if needed
			If $nPos > UBound($aRetVal) Then ReDim $aRetVal[$nPos]
			$aRetVal[$nPos] = $aArray[0][$I]
			$nPos += 1
		EndIf
	Next
	Return $aRetVal
EndFunc   ;==>AssocArrayKeys

#cs
	Function:  AssocArraySave
	Purpose:  Save an associative array in a text file.
	Parameters:
	$aArray:  The array containing an associative array.
	$sFilename:  The name of the text file to store the array
	Return value:  Returns true if the file was saved.  False otherwise.
	Notes:  The directory must already exist and have write permission.  An existing file will be overwritten.
#ce
Func AssocArraySave(ByRef Const $aArray, Const $sFilename)
	Local $fOut, $I, $bStatus = True

	If AssocArrayVerify($aArray) = False Then
		SetError(2)
		Return False
	EndIf
	$fOut = FileOpen($sFilename, 2)
	If $fOut < 0 Then Return False

	For $I = 1 To UBound($aArray, 2) - 1
		If $aArray[0][$I] = "" Then
			; Skip records with empty keys
		ElseIf FileWriteLine($fOut, StringQuote($aArray[0][$I]) & ", " & StringQuote($aArray[1][$I])) = 0 Then
			$bStatus = False
			ExitLoop
		EndIf
	Next
	FileClose($fOut)
	Return $bStatus
EndFunc   ;==>AssocArraySave

#cs
	Function:  AssocArrayLoad
	Purpose:  Get the value of an element in an associative array.
	Parameters:
	$aArray:  The array containing an associative array.  It could be partially populated already.
	$sFilename:  The name of the text file which holds the array.
	Return value:  Returns true if the file was loaded.  Sets @Error otherwise and returns false.
	@Error = 1:  File not found or could not be read.
	@Error = 2:  File format is invalid.
	@Error = 3:  Interal problems with regular expression pattern.
	Notes:  The function will read most CSV files and put the first two fields in the associative array as key, data.
#ce
Func AssocArrayLoad(ByRef $aArray, Const $sFilename)
	Local $fIn, $sKey, $vValue
	Local $sLine
	Local $aRawData

	$fIn = FileOpen($sFilename, 0)
	If $fIn < 0 Then
		SetError(1)
		Return False
	EndIf
	If AssocArrayVerify($aArray) = False Then
		; Build the array
		AssocArrayCreate($aArray, 99) ; Typical starting value
	EndIf
	; Infinite loop, broken inside
	While True
		$sLine = FileReadLine($fIn)
		If @error <> 0 Then
			ExitLoop
		EndIf
		If $gbAA_Debug Then ConsoleWrite("$sLine = " & $sLine & @CRLF)
		$sLine = StringStripWS($sLine, 3)
		If $sLine > "" Then
			$aRawData = CVSParse($sLine)

			; $aRawData is a 1D array containing every field in the CSV file.
			If $gbAA_Debug Then
				For $I = 0 To UBound($aRawData) - 1
					ConsoleWrite("$aRawData[" & $I & "] = " & $aRawData[$I] & @CRLF)
				Next
			EndIf
			$sKey = $aRawData[0]
			$vValue = $aRawData[1]
			AssocArrayAssign($aArray, $sKey, $vValue)
		EndIf
	WEnd
	FileClose($fIn)
	Return True
EndFunc   ;==>AssocArrayLoad

; Support functions.

#cs
	Function:  NotPrime
	Purpose:  Determine if a number is not prime.  Support function for hash table.
	Parameters:
	$nValue:  The value to test for prime.
	Return value:  True if number is not prime.  False if prime.  Sets @Error to 1 if not an integer.
	Notes:
#ce
Func NotPrime(Const $nValue)
	Local $nTest

	If StringIsInt($nValue) = 0 Then
		Return False
	ElseIf $nValue < 2 Then
		; Lowest prime is two.  Smaller numbers do not qualify.
		Return True
	EndIf
	For $nTest = 2 To Int(Sqrt($nValue))
		If Round(Mod($nValue, $nTest)) = 0 Then
			; Has a factor of $nTest.  Composite!
			Return True
		EndIf
	Next
	Return False ; Is Prime
EndFunc   ;==>NotPrime

#cs
	Function:  HashPos
	Purpose:  Give the position to look for the given key in the hash table.
	Parameters:
	$sKey:  The key value in the hash table
	$nSize:  The size of the hash table to work with.
	Return value:  The hash table position determined from the given key.
	Notes:  Based on Jenkins One at a time hash (see http://en.wikipedia.org/wiki/Hash_table,
	http://www.burtleburtle.net/bob/hash/doobs.html)
#ce
Func HashPos(Const $sKey, Const $nSize)
	Local $nPos = 0, $I

	For $I = 1 To StringLen($sKey)
		$nPos += Asc(StringMid($sKey, $I, 1))
		$nPos += _UBitShift($nPos, -10)
		$nPos = BitXOR($nPos, _UBitShift($nPos, 6))
	Next
	$nPos += _UBitShift($nPos, -3)
	$nPos = BitXOR($nPos, _UBitShift($nPos, 11))
	$nPos += _UBitShift($nPos, -15)
	$nPos = Round(Mod(Abs($nPos), $nSize))
	Return $nPos
EndFunc   ;==>HashPos

#cs
	Function:  Rehash_Grow
	Purpose:  Grow the array by the amount stored in the array.
	Parameters:
	$aArray:  The array containing an associative array.
	Return value:  True is is could resize and array.  False otherwise.
#ce
Func Rehash_Grow(ByRef $aArray)
	Local $nPos = 0, $I
	Global $gbAA_Rehash = False

	If $gbAA_Rehash Then
		; If already in a rehash cycle, abort due to cascading rehashs.
		MsgBox(48, "AssocArrayAssign", "Cascading rehash caused by poor hash function.  Aborting.  Revise hash function and retry.")
		Exit
	Else
		$gbAA_Rehash = True
	EndIf

	If AssocArrayVerify($aArray) = False Then
		SetError(2)
		Return False
	EndIf

	If $aArray[1][0] = 0 Then
		; No growth.
		Return False
	EndIf
	; Grow the array, reassign the values and try again.
	Local $nHashSize = Ceiling(UBound($aArray, 2) * (1 + $aArray[1][0]))

	While NotPrime($nHashSize)
		$nHashSize += 1
	WEnd

	If $gbAA_Debug Then ConsoleWrite("Rehash_Grow:  Used = " & $aArray[0][0] & ", After collisions $nPos = " & $nPos & ".  Resizing to " & $nHashSize & @CR)

	Local $aTmp[2][$nHashSize + 1] ; New size.  The +1 is to accomodate that index 0 is being used for housekeeping.
	$aTmp[0][0] = 0 ; Active array size
	$aTmp[1][0] = $aArray[1][0] ; Copy the growth rate

	; Assign the old values
	For $I = 1 To UBound($aArray, 2) - 1
		If $aArray[0][$I] > "" Then
			AssocArrayAssign($aTmp, $aArray[0][$I], $aArray[1][$I])
		EndIf
	Next
	$aArray = $aTmp
	$gbAA_Rehash = False
	Return True
EndFunc   ;==>Rehash_Grow

#cs
	Function:  _UBitShift
	Purpose:  Perform an unsigned bit shift
	Parameters:
	$nValue:  The value to be shifted
	$nShift:  The number of bits to shift
	Return value:  The shifted value
	Notes:  Found on http://www.autoitscript.com/forum/index.php?showtopic=58982 and used without permission.  ;)
#ce
Func _UBitShift($nValue, Const $nShift)
	; Check for the sign bit.
	Local $bSignBit = False

	If BitAND($nValue, 0x80000000) Then
		; Sign bit found, unset it.
		$nValue = BitXOR($nValue, 0x80000000)
		$bSignBit = True
	EndIf
	; Do a signed shift with the sign bit unset.
	$nValue = BitShift($nValue, $nShift)
	; Check to see if the former sign bit needs set.
	If $nShift > 0 And $nShift < 32 And $bSignBit Then $nValue = BitOR($nValue, 2 ^ (31 - $nShift))
	Return $nValue
EndFunc   ;==>_UBitShift

#cs
	Function:  StringQuote
	Purpose:  Surround a string in quotes.  All other types, that can be, are converted to string.
	Parameters:
	$vValue:  The value to be checked / converted.
	Return value:  The value surrounded by quotes if a string.  Otherwise, the value converted to a string.
	Sets @Error = 1 if the value can not be converted to a string
	Notes:
#ce
Func StringQuote(Const $vValue)
	If IsString($vValue) Then
		Local $I, $M, $sRetVal = ""

		For $I = 1 To StringLen($vValue)
			$M = StringMid($vValue, $I, 1)
			Switch $M
				Case '"'
					$sRetVal &= '""'
				Case Else
					$sRetVal &= $M
			EndSwitch
		Next
		$sRetVal = '"' & $sRetVal & '"'
		Return $sRetVal
	Else
		Return String($vValue)
	EndIf
EndFunc   ;==>StringQuote

#cs
	Function:  CVSParse
	Purpose:  Identifies the Comma-Separated Values in the given string and returns them as an array
	Parameters:
	$sParse:  The string to be parsed.
	Return value:  A 1-dimensional array with each element of the CSV string in its own element.
	Sets @Error = 1 if the string is not in the correct format.  The return value will be False in this case.
	Notes:
#ce
Func CVSParse(Const $sParse)
	Local $I, $M
	Local $nCurrElement = 0
	Local $bQuote = False
	Local $aRetVal[StringLen($sParse)]

	For $I = 1 To StringLen($sParse)
		$M = StringMid($sParse, $I, 1)
		Switch $M
			Case '"'
				If Not $bQuote Then
					$bQuote = True
				ElseIf StringMid($sParse, $I + 1, 1) = '"' Then ; Inside a quoted string, do we have two quotes together?
					; Include the quote
					$aRetVal[$nCurrElement] &= $M
					$I += 1
				Else
					$bQuote = False
				EndIf
			Case ','
				If $bQuote Then
					$aRetVal[$nCurrElement] &= $M
				Else
					$nCurrElement += 1
				EndIf
			Case Else
				If Not $bQuote And $M = " " And $aRetVal[$nCurrElement] = "" Then
					; Skip it
				Else
					$aRetVal[$nCurrElement] &= $M
				EndIf
		EndSwitch
	Next
	If $nCurrElement > 0 Then ReDim $aRetVal[$nCurrElement + 1]
	Return $aRetVal
EndFunc   ;==>CVSParse