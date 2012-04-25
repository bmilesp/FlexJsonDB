package Libs
{
	public class BTreeIndex extends JsonDB
	{
		
		/**
		 * A B-tree style index for JSONDB collections
		 * @constructor
		 * @param name the name of the index
		 * @param definition an object defining the attributes to index and their individual sort orders
		 * @param collection the JSONDB collection to index
		 */
		public function BTreeIndex(name, definition, collection) {
			
			protected var _count = 0;
			protected var _name = name;
			protected var _definition = definition;
			protected var _collection = collection;
			protected var _k = [];
			protected var _o = [];
			protected var _btree = {};
			protected var _rleaves = {};
			
			/**
			 * Returns the index type for the given index
			 * @return integer
			 */
			public function getType() {
				return INDEX_TYPE_B_TREE;
			}
			
			/**
			 * Clears the index
			 * @return void
			 */
			public function clear() {
				_btree = {};
				_rleaves = {};
			};
			
			/**
			 * Checks whether a given property is included in the index
			 * @param property the property to check
			 * @return boolean
			 */
			public function includesProperty(property) {
				for(var i=0; i < _k.length; i++) {
					if(_k[i] == property) {
						return true;
					}
				}
				return false;
			};	
			
			for(var __k in _definition) {
				_k.push(__k);
				_o.push(parseInt(_definition[__k]));
			}
			
			/**
			 * Builds the index using the provided collection
			 * @return void
			 */
			public function index() {
				clear();
				var ts =  new Date().time;
				_recursivelyBuildIndex(_btree, _k.slice(), _o.slice(), _collection.getAll());
				debug('building index ' + _name + ' with ' + _count + ' nodes took ' + ( new Date().time - ts) + ' ms');
			};
			
			protected function _recursivelyBuildIndex(btree, keys, order, objects) {
				// set up variables
				var k = keys.shift();
				var k2 = [];
				var v = order.shift();
				var o = {};
				var c = 0;
				var r = _rleaves;
				// iterate objects
				var k3 = null;
				objects.forEach(function(object) {
					tcache = {};
					k3 = traverse(k, object);
					if(k3 !== undefined) {
						if(o[k3] == undefined) {
							o[k3] = [];
							k2.push(k3);
						}
						o[k3].push(object);
					}
				});
				if(v < 0) {
					k2.sort(function(v1, v2){return v2 - v1;});
				} else {
					k2.sort(function(v1, v2){return v1 - v2;});			
				}
				// set up b-tree index
				var l = k2.length;
				for(var i=0; i < l; i++) {
					k3 = k2[i];
					if(typeof(k3) == 'object') {
						continue;
					}
					btree[k3] = {};
					if(keys.length == 0) {
						o[k3].forEach(function(object) {
							btree[k3][object.$id] = object; // forward look-up (i.e. root to leaf)
							r[object.$id] = btree[k3]; // reverse look-up (i.e. leaf to root)
							c++;
						});
					} else {
						_recursivelyBuildIndex(btree[k3], keys.slice(), order.slice(), o[k3]);
					}
				}		
				_count += c;
			};
			
			/**
			 * Traverses the index using the provided query expression object and returns a list of matching objects
			 * @param query the query expression object
			 * @return array
			 */
			public function find(query) {
				var ts =  new Date().time;
				var o = {};
				var a = {scanned:0}; // analytics
				var or = null;
				if($or in query) {
					or = query.$or;
					delete query[$or];
				}
				_recursiveFind(query, _btree, 0, o, a);
				if(or !== null) {
					var o3 = _collection.find(or);
					o3.forEach(function(object) {
						o[object.$id] = object;
					});
				}
				var o2 = [];
				for(var i in o) {
					o2.push(o[i]);
				}
				return o2;
			};
			
			protected function _recursiveFind(query, leaf, i, o, a) {
				var v = null;
				var l = _k.length;
				if(i >= l) {
					return;
				}
				
				v = query[_k[i]];
				if(v instanceof RegExp) {
					for(var k in leaf) {
						a.scanned++;
						if(typeof(k) !== 'string') {
							k = new String(k);
						}
						if(k.match(v) !== null) {
							if(i < (_k.length - 1)) {
								_recursiveFind(query, leaf[k], i+1, o, a);
							} else {
								for(var k1 in leaf[k]) {
									o[k1] = leaf[k][k1];
								}
							}						
						}
					}
				} if(typeof(v) == 'object') {
					for(var k in leaf) {
						a.scanned++;
						include = true;
						for(var f in v) {
							switch(f) {
								case $eq:
									if(k != v[f]) {
										include = false;
									}
									break;
								
								case $ne:
									if(k == v[f]) {
										include = false;
									}
									break;
								
								case $gt:
									if(k <= v[f]) {
										include = false;
									}
									break;
								
								case $gte:
									if(k < v[f]) {
										include = false;
									}
									break;
								
								case $lt:
									if(k >= v[f]) {
										include = false;
									}
									break;
								
								case $lte:
									if(k > v[f]) {
										include = false;
									}
									break;
							}
						}
						if(include == true) {
							if(i < (_k.length - 1)) {
								_recursiveFind(query, leaf[k], i+1, o, a);
							} else {
								for(var k1 in leaf[k]) {
									o[k1] = leaf[k][k1];
								}
							}
						}
					}
				} else {
					if(!(v in leaf)) {
						return [];
					}
					if(i == (_k.length - 1)) {
						for(var k in leaf[v]) {
							o[k] = leaf[v][k];
						}					
					} else {
						a.scanned++;
						_recursiveFind(query, leaf[v], i+1, o, a);
					}
				}
			};
			
			/**
			 * Removes an object from the index
			 * @param o the object to remove
			 * @return void
			 */
			public function remove(o) {
				if(o.$id in _rleaves) {
					delete _rleaves[o.$id][o.$id];
					delete _rleaves[o.$id];
				}
			};
			
			/**
			 * Inserts an object into the index
			 * @param o the object to add to the index
			 * @return boolean
			 */
			public function insert(o) {
				for(var k in _definition) {
					if(traverse(k, o) == undefined) {
						return false;
					}
				}
				remove(o);
				var v    = null;
				var leaf = _btree;
				for(var k in _definition) {
					v = o[k];
					if(!(v in leaf)) {
						leaf[v] = {};
					}
					leaf = leaf[v]
				}
				leaf[o.$id] = o;
				_rleaves[o.$id] = leaf;
			};
			
		};
	}
}