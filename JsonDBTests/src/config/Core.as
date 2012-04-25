package config
{
	public class Core
	{
		//public static var baseUrl:String = "http://192.168.1.108/GoodTaco"; 
		public var debug:int = 2;
		//public var debugDB:String = '/data/data/air.com.brandonplasters.mobileApps.WwH.debug/com.brandonplasters.mobileApps.WwH.debug/Local Store'
		public var debugDB:String =	'C:/bp/mobile_apps/WwHSuite/WwHTests/src/JsonDBSuite/';
		//public var testsDB:String =	'C:/bp/mobile_apps/WwHSuite/WwHTests/src/wwhSuite/';
		//for unit tests (must have debug set to level 2 for debugDBFilename to take effect)
		public var testsDBFilename:String = 'jsonDB-test.db';
		
		//for use with FlakephpTests in cakephp. see libs/FlakephpTestsUtils
		//public static var flakephpTestsPrefixUrl:String = "/flakephp_tests/";
		
		public function Core(){}
	}
}