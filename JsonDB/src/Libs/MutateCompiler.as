package Libs
{
	public class MutateCompiler extends JsonDB
	{
		
		protected var _cache = {};
		
		/**
		 * Factory wrapper that generates a QueryClosure instance used specifically to mutate collection data
		 * @constructor
		 */		
		public function MutateCompiler()
		{
		}
		
		/**
		 * Compiles the QueryClosure instance for the provided list of expressions and returns it
		 * @param updates the list of update expressions
		 * @return QueryClosure
		 */
		public function compile(updates) {
			var closure = new QueryClosure(updates);
			_compile(updates, closure);
			return closure;
		};
		
		protected function _compile(updates, closure) {
			for(var key in updates) {
				switch(key)
				{
					case '$unset':
					case '$inc':
					case '$set':
						for(var skey in updates[key]) {
							var args = [];
							args.push(skey);
							args.push(updates[key][skey]);
							closure.addUpdateFunction(exports.JSONDB.functions[key], args);
						}
						break;
				}
			}
		};
	}
}