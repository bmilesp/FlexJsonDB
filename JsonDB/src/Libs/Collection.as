package Libs
{
	public class Collection extends JsonDB
	{
		
		protected var _secret;
		protected var _path;
		protected var _indexes = {};
		protected var _indexed = false;
		protected var _io = FilesystemManager;
		protected var _api;
		protected var _collection = {
			_sig: null,
			_salt: null,
			_name: null,
			_version: 0.2,
			_objects: {},
			_lastInsertId: false
		};
		
		protected var _auto_commit = false;
		
		/**
		 * Represents a collection JavaScript objects
		 * @constructor
		 * @param name the name of the collection
		 * @param secret the secret to use in cryptographic operations
		 * @param the storage path for the collection
		 * @param override whether or not to override internal constraints on collection names
		 */
		public function Collection(name, secret, path, override) {
			_secret = secret;
			_path = path;
			_collection['_name'] = name;
			
			
			if(name == '__log' && override !== true) {
				throw 'The collection name __log is reserved for internal use by the JSONDB module';
			}
		}
		
		/**
		 * Creates an index using the provided definition (if it doesn't already exist)
		 * @param definition the definition to use when creating the index. This object should be a table of key value pairs with the keys representing the object attributes to index and values representing the sort order for the index branch (-1 descending, 1 ascending)
		 * @return void
		 */
		public function ensureIndex(definition) {
			var d = sortObjectKeys(definition);
			var n = generateIndexName(d, false);
			if(n in this._indexes) {
				return;
			} else {
				this._indexes[n] = new BTreeIndex(n, d, this);
				this._indexes[n].index();				
			}
			this._indexed = true;
		};
		
		/**
		 * Selects and returns the most appropriate b-tree index for the provided query expression object. If no index can be found to service the query the boolean value FALSE is returned.
		 * @param query the query expression object
		 * @return BTreeIndex/boolean
		 */
		public function selectIndex(query) {
			var n = generateIndexName(sortObjectKeys(query), false);
			if(n in this._indexes) {
				trace('using index ' + n);
				return this._indexes[n];
			}
			if(sizeOf(this._indexes) == 0) {
				this._indexed = false;
			}
			return false;
		};
		
		/**
		 * Drops the index corresponding to the provided definition (if it exists)
		 * @param definition the definition to use when removing the index.
		 * @return boolean
		 */
		public function dropIndex(definition) {
			var d = sortObjectKeys(definition);
			var n = generateIndexName(d, false);
			if(n in this._indexes) {
				delete this._indexes[n];
				return true;
			} else {
				return false;
			}
		};
		
		/**
		 * Sets whether or not the collection automatically commits to disk (defaults to false)
		 * @param value the boolean value to set on the collection
		 * @return void
		 */
		public function setAutoCommit(value) {
			this._auto_commit = value;
		};
		
		/**
		 * Initializes the MongoLab REST API connector for the collection
		 * @param host the host name for the API
		 * @param key the API key to use in HTTP requests
		 * @param query an query expression object used to filter objects when retrieving collections from the MongoLab REST API
		 * @return void
		 */
		public function initializeAPI(host, key, query) {
			_api = new MongoRESTManager(this._collection._name, host, key, query);
		};
		
		/**
		 * Returns the length of the collection (i.e. how many objects it contains)
		 * @return integer
		 */
		public function sizeOf() {
			return sizeOf(this._collection._objects);
		};
		
		/**
		 * Returns the ObjectId of the last object to be added to the collection
		 * @return string
		 */
		public function getLastInsertId() {
			return this._collection._lastInsertId;
		};
		
		/**
		 * Loads the collection data from disk
		 * @return void
		 */
		public function open() {
			var c = _io.load(_collection['_name'], _secret, _path);
			if(c !== false) {
				_collection = c;
				_unflatten(_collection._objects);
			}
		};
		
		protected function _unflatten(objects) {
			for(var key in objects) {
				if(typeof(objects[key]) === 'object' && objects[key] !== null) {
					if('$ref' in objects[key]) {
						objects[key] = new DBRef(objects[key]);
					} else {
						_unflatten(objects[key]);
					}
				}
			}
		};
		
		/**
		 * Retrieves a list of objects from the collection
		 * @param query the query expression object to use when filtering the collection
		 * @param conditions the conditions to apply to the result set
		 * @return array
		 */
		public function find(query, conditions) {
			var ts =  new Date().time;
			if(typeof(query) === 'undefined') {
				query = {};
			}
			if(ID_FIELD in query) {
				var r = [];
				if(!(query.$id in _collection._objects)) {
					return r;
				}
				r.push(_collection._objects[query.$id]);
				return r;
			}
			var closure = QueryCompiler.compile(query);
			var tuples = closure.execute(this);
			if(typeof(conditions) !== 'undefined') {
				if('$sort' in conditions) {
					var key, order = 0;
					for(key in conditions.$sort) {
						order = conditions.$sort[key];
						break;
					}
					$sort(tuples, key, order);
				}
				if('$limit' in conditions) {
					if(conditions.$limit < tuples.length) {
						tuples = tuples.slice(0, conditions.$limit);
					}
				}
			}
			trace('Collection.find (' + _collection._name + ':' + stringify(query) + ' , ' +  stringify(conditions) + ') took ' + ( new Date().time - ts) + ' ms');
			return tuples;
		};
		
		/**
		 * Clears the collection (i.e. removes all objects)
		 * @return void
		 */
		public function clear() {
			_collection._objects = {};
			for(var n in _indexes) {
				_indexes[n].clear();
			}		
		};
		
		/**
		 * Returns an array containing references to all objects in the collection
		 * @return array
		 */
		public function getAll() {
			var ts =  new Date().time;
			var objects = [];
			for(var key in _collection._objects) {
				objects.push(_collection._objects[key]);
			}
			trace('Collection.getAll (' + _collection._name + ') took ' + ( new Date().time - ts) + ' ms');
			return objects;
		};
		
		/**
		 * Adds an object to the collection
		 * @param o the object to add to the collection
		 * @return void
		 */
		public function save(o) {
			var ts =  new Date().time;
			if(!(ID_FIELD in o)) {
				o.$id = generateBSONIdentifier();
				_collection._lastInsertId = o.$id;
			}
			_collection._objects[o.$id] = o;
			for(var n in _indexes) {
				_indexes[n].insert(o);
			}
			if(_auto_commit) {
				commit();
			}
		};
		
		/**
		 * Updates a series of objects in the collection
		 * @param query the query expression object to use when filtering the collection
		 * @param updates the updates to apply the matching objects
		 * @param conditions the conditions to apply to the result set
		 * @param upsert a boolean flag indicating whether or not to insert missing object attributes
		 * @return array
		 */
		public function update(query, updates, conditions, upsert) {
			var ts =  new Date().time;
			if(typeof(upsert) == 'undefined') {
				upsert = false;
			}
			var closure = MutateCompiler.compile(updates);
			var objects = find(query, conditions);
			closure.executeUpdate(objects, upsert);
			var l = objects.length;
			for(var n in _indexes) {
				for(var i=0; i < l; i++) {
					_indexes[n].insert(objects[i]);
				}
			}
			trace('Collection.update (' + _collection._name + ':' + stringify(updates) + ') took ' + ( new Date().time - ts) + ' ms');
			return objects.length;
		};
		
		/**
		 * Returns a count of the objects extracted by the provided query expression object
		 * @param query the query expression object to user
		 * @return integer
		 */
		public function count(query) {
			return find(query).length;
		}
		
		/**
		 * Returns an object containing key, value pairs representing the distinct values for the provided key (and query if provided)
		 * @param key the key to find distinct values for
		 * @param query the query to use when aggregating results
		 * @return object
		 */
		public function distinct(key, query) {
			var o = find(query);
			var t = {};
			o.forEach(function(d) {
				if(!(d[key] in t)) {
					t[d[key]] = 0;
				}
				t[d[key]]++;
			});
			return t;
		};
		
		/**
		 * Removes all objects from the collection that correspond to the provided query expression and conditions. Returns the number of objects removed from the collection.
		 * @path query the query expression object to user
		 * @path conditions the conditions for the query
		 * @return integer
		 */
		public function remove(query, conditions) {
			var ts =  new Date().time;
			var objects = find(query, conditions);
			var l = objects.length;
			var r = (_api !== null);
			
			var ts2 =  new Date().time;
			for(var i=0; i < l; i++) {
				var o = objects[i];
				delete _collection._objects[o.$id];
				for(var n in _indexes) {
					_indexes[n].remove(o);
				}
				if(r) {
					Log.save({
						$id: o.$id,
						cl: _collection._name,
						ts:  new Date().time,
						cm: "delete",
						o: o
					});
				}
			}
			if(_indexed == true) {
				trace('took ' + ( new Date().time - ts2) + ' ms to update all indexes for ' + objects.length + ' records');
			}
			if(r) {
				Log.commit();
			}
			if(_auto_commit) {
				commit();
			}
			trace('Collection.remove (' + _collection._name + ') took ' + ( new Date().time - ts) + ' ms');
			return objects.length;
		};
		
		/**
		 * Commits the collection data to disk
		 * @return void
		 */
		public function commit() {
			var ts =  new Date().time;
			_io.save(_collection['name'], _collection, _secret, _path);
		};
		
	};
}