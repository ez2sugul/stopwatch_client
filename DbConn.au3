#include "mysql.au3"

Func GetSQLCreateTable($sTable)
   $sQryCreateTable = "CREATE TABLE IF NOT EXISTS `" & $sTable & "` (" & _
	  "`id` int(11) unsigned NOT NULL AUTO_INCREMENT," & _
	  "`serviceName` varchar(80) DEFAULT NULL COMMENT '테스트 서비스 이름'," & _
	  "`deviceName` varchar(80) DEFAULT NULL COMMENT '테스트 장비 이름'," & _
	  "`actionName` varchar(80) DEFAULT NULL COMMENT '측정하고자 하는 이미지'," & _
	  "`actionDate` datetime NOT NULL COMMENT '측정을 시작한 시각 '," & _
	  "`startTime` int(11) DEFAULT NULL COMMENT '측정을 시작한 ms'," & _
	  "`durationTime` int(11) DEFAULT NULL COMMENT '측정에 소요된 ms'," & _
	  "`isError` tinyint(1) DEFAULT NULL COMMENT '측정 시 오류 유무'," & _
	  "PRIMARY KEY (`id`)," & _
	  "UNIQUE KEY `serviceName_2` (`serviceName`, `actionName`, `deviceName`, `actionDate`), " & _
	  "KEY `actionDate` (`actionDate`)," & _
	  "KEY `serviceName` (`serviceName`)," & _
	  "KEY `isError` (`isError`)," & _
	  "KEY `actionName` (`actionName`)" & _
	") ENGINE=InnoDB DEFAULT CHARSET=utf8;"

	return $sQryCreateTable
 EndFunc

Func GetSQLUseDatabase($sDbName)
   $sQryUseDB = "USE " & $sDbName
   return $sQryUseDB
EndFunc

Func GetErrorCount($table, $app_key, $deviceName)
	$sQryGetErrorCount = "SELECT count1.c as c1, count2.c as c2 FROM " & _
	" (SELECT count(*) c FROM " & $table & _
	" WHERE serviceName = '" & $app_key & "' AND deviceName = '" & $deviceName & "' AND timediff(now(), actionDate) <= '00:59:59') count1, " & _
	" (SELECT count(*) c FROM " & $table & _
	" WHERE serviceName = '" & $app_key & "' AND deviceName = '" & $deviceName & "' AND isError = '1' AND timediff(now(), actionDate) <= '00:59:59') count2"

	Return $sQryGetErrorCount
EndFunc