package JsonDBSuite
{
	import libs.FlakephpTestsUtils;
	
	import models.Match;
	import models.MatchesUser;
	import models.PlayedHand;
	
	import mx.utils.ObjectUtil;
	
	import JsonDBSuite.tests.TestJsonDBCase;
	import JsonDBSuite.tests.TestModelCase;
	import JsonDBSuite.tests.TestRemoteMethodsCase;

	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class JsonDBSuite
	{
		public var t1:TestModelCase
		public var t2:TestJsonDBCase
		public var t3:TestRemoteMethodsCase

	}
}