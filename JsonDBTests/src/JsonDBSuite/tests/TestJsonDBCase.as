package JsonDBSuite.tests
{
	import libs.OUtils;
	import mx.utils.ObjectUtil;
	import org.flexunit.Assert;

	public class TestJsonDBCase
	{	
		//private var match:Match;
		//private var matchesUser:MatchesUser;
		//private var hUrlRequest:HeaderURLRequest;
		
		[Before]
		public function setUp():void
		{
			//match = new Match();
			//matchesUser = new MatchesUser();
			//hUrlRequest = new HeaderURLRequest();
		}
		
		[After]
		public function tearDown():void
		{
		}
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		[Test( description = "jsonDB init" )]
		public function jsonDBInit():void 
		{
		
			//Assert.assertEquals( OUtils.varExport(expected), OUtils.varExport(result) );
		}
		
	}
}