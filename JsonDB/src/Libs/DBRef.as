package Libs
{
	public class DBRef extends JsonDB
	{
		public var $ref;
		public var $id;
		
		public function DBRef(struct) {
			
			if(typeof(struct) !== 'object'
				|| !(REF_FIELD in struct)
				|| !(ID_FIELD in struct)) {
				throw "illegal object reference";
			}
			
			$ref = struct.$ref;
			$id = struct.$id;
			
			/**
			 * Returns the collection name for the DBRef instance
			 * @return string
			 */
			public function getCollection() {
				return this.$ref;
			};
			
			/**
			 * Returns the BSON Object Identifier for the DBRef instance
			 * @return string
			 */
			public function getObjectId() {
				return this.$id;
			};
			
			/**
			 * Resolves the object that the DBRef actually references
			 * @return object/boolean
			 */
			public function resolve() {
				var o = Database.getCollection(this.$ref).find({$id:this.$id});
				if(o !== false) {
					return o[0];
				}
				return false;
			};
			
		};
	}
}