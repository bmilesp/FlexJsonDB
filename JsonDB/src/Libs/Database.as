package Libs
{	
	/**
	 * the JSONDB database interface class
	 * @constructor
	 */
	public class Database extends JsonDB
	{
			
		public function Database(){}
		
		protected var _collections = {};	
		
		/**
		 * Factories are new JSONDB Collection instance. Collection objects are singleton instances - the pattern is implemented in this factory function.
		 * @param name the name of the collection to factory
		 * @param secret the shared secret to use when signing data for the collection
		 * @param path the file system location store collection data to
		 * @param override whether or not to override collection name restrictions
		 * @return JSONDB Collection instance
		 */
		public function getCollection(name, secret, path, override) {
			if(name in _collections) {
				return _collections[name].c;
			}
			var collection = new Collection(name, secret, path, override);
			collection.open();
			_collections[name] = {
				c:collection,
				t: new Date().time
			}
			return _collections[name].c;
		};	
		
	};
	
	}
}