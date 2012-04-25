package Libs
{
	public class QueryCompiler extends JsonDB
	{
		protected var _cache = {};
		
		public function QueryCompiler() {
		}
			
			
		/**
		 * Compiles the QueryClosure instance for the provided list of expressions and returns it
		 * @param query the list of query expressions
		 * @return QueryClosure
		 */	
		public function compile(query) {
			var closure = new QueryClosure(query);
			this._compile(query, closure, false);
			return closure;
		};
		
		public function _compile(query, closure, or) {
			for(var key in query) {
				var value = query[key];
				switch(typeof(value)) {
					case 'object':
						if(key == $or) {
							this._compile(value, closure, true);
						} else {
							for(var func in value) {
								switch(func)
								{
									case '$eq':
									case '$ne':
									case '$exists':
									case '$size':
									case '$within':
									case '$gt':
									case '$gte':
									case '$lt':
									case '$lte':
									case '$in':
									case '$sort':
									case '$unset':
									case '$inc':
									case '$set':
										this._addFunction(closure, exports.JSONDB.functions[func], [key, value[func]], or);
										break;
								}
							}
						}
						break;
					
					default:
						this._addFunction(closure, $eq, [key, value], or);
						break;
				}
			}
		};
		
		protected function _addFunction(closure, func, args, or) {
			if(or) {
				closure.addOrFunction(func, args);
			} else {
				closure.addAndFunction(func, args);
			}
		};
	}
}