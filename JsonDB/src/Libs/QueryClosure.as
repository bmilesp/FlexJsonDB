package Libs
{
	public class QueryClosure extends JsonDB
	{
		
		protected var _query;
		
		protected var _andFunctions = [];
		protected var _andArguments = [];
		
		protected var _orFunctions = [];
		protected var _orArguments = [];
		
		protected var _updateFunctions = [];
		protected var _updateArguments = [];
		
		public function QueryClosure(query) {
			_query = query;
		}
			
		/**
		 * Adds a closure (and arguments) to the call stack
		 * @param closure the closure to add to the stack
		 * @param args the arguments to add for the closure
		 * @return void
		 */
		public function addAndFunction(closure, args) {
			this._andFunctions.push(closure);
			this._andArguments.push(args);
		};
		
		/**
		 * Adds a closure (and arguments) to the call stack - executed as part of an $or execution branch
		 * @param closure the closure to add to the stack
		 * @param args the arguments to add for the closure
		 * @return void
		 */	
		public function addOrFunction(closure, args) {
			this._orFunctions.push(closure);
			this._orArguments.push(args);
		};
		
		/**
		 * Adds a closure (and arguments) to the call stack - closures in this stack mutate collection data
		 * @param closure the closure to add to the stack
		 * @param args the arguments to add for the closure
		 * @return void
		 */
		public function addUpdateFunction(closure, args) {
			this._updateFunctions.push(closure);
			this._updateArguments.push(args);
		};
		
		/**
		 * Executes the call stack of closures against the provided collection
		 * @param collection the collection to execute the call stack against
		 * @return the objects extracted by the query closures
		 */
		public function execute(collection) {
			var index = collection.selectIndex(this._query);
			if(index !== false) {
				return index.find(this._query);
			}
			var objects = [];
			var doOrs = this._orFunctions.length > 0;
			for(var key in collection._collection._objects) {
				tcache = {};
				var include = this._evaluate(this._andFunctions, this._andArguments, collection._collection._objects[key]);
				if(doOrs) {
					include = include || this._evaluate(this._orFunctions, this._orArguments, collection._collection._objects[key]);
				}
				if(include) {
					objects.push(collection._collection._objects[key]);
				}
			}
			return objects;
		};
		
		/**
		 * Executes a series of update closures against the provided objects
		 * @param objects the objects to mutate
		 * @param upsert a flag telling the call stack whether or not to perform an upsert in the event of a mission object parameter
		 * @return boolean
		 */
		public function executeUpdate(objects, upsert) {
			var l = objects.length;
			for(var i=0; i < l; i++) {
				this._evaluateUpdate(this._updateFunctions, this._updateArguments, objects[i], upsert);
			}
			return true;
		};
		
		protected function _evaluate(funcs, args, tuple) {
			var l = funcs.length;
			for(var i=0; i < l; i++) {
				if(funcs[i](args[i][0], args[i][1], tuple) == false) {
					return false;
				}
			}
			return true;
		};
		
		protected function _evaluateUpdate(funcs, args, tuple, upsert) {
			var i=0;
			funcs.forEach(function(f) {
				f(args[i][0], args[i][1], tuple, upsert);
				i++;
			});
		};	
	}
}