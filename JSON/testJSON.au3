;~ #noTrayIcon
opt('mustDeclareVars',1)
opt('trayIconDebug',1)

#include "JSON.au3"
#include "JSON_Translate.au3" ; examples of translator functions, includes JSON_pack and JSON_unpack

local $t=_JSONEncode( _
	_JSONArray( _
		true, _
		false, _
		_JSONArray(), _
		_JSONObject(), _
		$_JSONNull, _
		binary('0x1234'), _
		_JSONObject( _
			'test',$_JSONNull, _
			'also',3, _
			'yes?',true, _
			'whee!',_JSONArray( _
				true, _
				false, _
				3, _
				4, _
				$_JSONNull _
			) _
		) _
	),'JSON_pack' _
)

msgbox(0,default,$t)
;~ msgbox(0,default,$_JSONErrorMessage)
msgbox(0,default,_JSONEncode(_JSONDecode($t,'JSON_unpack'),'JSON_pack','  '))
msgbox(0,default,_JSONEncode(_JSONDecode($t,'JSON_unpack'),'JSON_pack','  ',@LF,true))

local $s='[true,[],false,"",3,[4.2,0xD,4e23,-0xF,null,0xFFFFFFFF,"\u0064-Hi!\u201D\uFEFF"],{}]'
msgbox(0,default,_JSONEncode(_JSONDecode($s)))

local $s2='{"test":' & $s & '}'
msgbox(0,default,_JSONEncode(_JSONDecode($s2)))

