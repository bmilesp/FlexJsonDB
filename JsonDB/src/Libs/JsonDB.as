package Libs {
	import flash.events.EventDispatcher;
	
	class JsonDB extends EventDispatcher {
		 /**
		 *   JSONDB is a module for Titanium that allows you to create, query and store collections of JavaScript objects in your iOS applications. 
		 *   All data managed by JSONDB is secured from tampering once committed to storage. JSONDB provides an advanced NoSQL query interface allowing 
		 *   traversal, retrieval, mutation and sorting of objects within collections.
		 *   
		 *   Copyright (C) 2012 IRL Gaming Pty Ltd (ohlo@irlgaming.com)
		 *
		 *   This program is free software: you can redistribute it and/or modify
		 *   it under the terms of the GNU General Public License as published by
		 *   the Free Software Foundation, either version 3 of the License, or
		 *   (at your option) any later version.
		 *
		 *   This program is distributed in the hope that it will be useful,
		 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
		 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		 *   GNU General Public License for more details.
		 *
		 *   You should have received a copy of the GNU General Public License
		 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
		 */
		
		/**
		 * Global module name space
		 
		var exports = {
			JSONDB: {
				classes: {},
				objects: {},
				functions: {},
				variables: {},
				constants: {}
			}
		};
		*/
		
		// the variables below are used for string comparison operations
		public var $eq = "$eq";
		public var $ne = "$ne";
		public var $exists = "$exists";
		public var $size = "$size";
		public var $within = "$within";
		public var $gt = "$gt";
		public var $gte = "$gte";
		public var $lt = "$lt";
		public var $lte = "$lte";
		public var $in = "$in";
		public var $in = "$nin";
		public var $or = "$or";
		public var $sort = "$sort";
		public var $unset = "$unset";
		public var $inc = "$inc";
		public var $set = "$set";
		
		// the object deletion log for collections linked to MongoDB collections
		public var Log
		
		/**
		 * Global variables
		 */
		// flag specifying whether or not to log debug output to the console
		public var debug = false;
		
		// a cache used to store traversal information for objects between inner loop iterations
		public var tcache = {};
		
		/**
		 * Global constants
		 */
		public const INDEX_TYPE_B_TREE = 0;
		public const INDEX_TYPE_UNIQUE = 1;
		public const DEFAULT_API_HOST = 'api.mongolab.com';
		public const DEFAULT_FS_DIR = Titanium.Filesystem.applicationDataDirectory;
		public const ID_FIELD = '$id';
		public const REF_FIELD = '$ref';
		
		public function JsonDB(){
			Log = factory('___log', 'repl:C7E7CB377BADE1D68BA0FFBD03347CA18D746817AC50CE407EA40BE5677ACB9D', undefined, true);
		}
		
		
		/**
		 * Query expression closures below
		 */
		public function $eq(a, b, c) {
			var v = traverse(a, c);
			if(v === undefined) {
				return false;
			}
			if(b instanceof RegExp || typeof(b) == 'function') {
				if(typeof(v) !== 'string') {
					v = new String(v);
				}
				return v.match(b) !== null;
			} else if(typeof(v) =='object' && (v instanceof Array)) {
				for(var i=0; i < v.length; i++) {
					if(b == v[i]) {
						return true;
					}
				}
				return false;
			} else {
				return v == b;
			}
		};
		
		public function $ne(a, b, c) {
			var v = traverse(a, c);
			if(v === undefined) {
				return false;
			}
			if(b instanceof RegExp || typeof(b) == 'function') {
				if(typeof(v) !== 'string') {
					v = new String(v);
				}
				return v.match(b) == null;
			} else if(typeof(v) =='object' && (v instanceof Array)) {
				for(var i=0; i < v.length; i++) {
					if(b == v[i]) {
						return false;
					}
				}
				return true;
			} else {
				return v != b;
			}
		};
		
		public function $exists(a, yes, b) {
			var v = traverse(a, b);
			if(yes) {
				return v !== undefined;
			}
			return v === undefined;
		};
		
		public function $size(a, b, c) {
			var v = traverse(a, c);
			if(v instanceof Array || typeof(v) === 'string') {
				return v.length == b;
			} else {
				var size = 0, key;
				for (key in v) {
					if (v.hasOwnProperty(key)) size++;
				}
			    return b == size;
			}
		};
		
		public function $within(a, b, c) {
			var v = traverse(a, c);
			if(!('lat' in v) || !('lng' in v)) {
				return false;
			}
			var d = Math.sqrt(Math.pow(b[0][0] - v.lat, 2) + Math.pow(b[0][1] - v.lng, 2));
			return (d <= b[1]);
		};
		
		public function $gt(a, b, c) {
			return traverse(a, c) > b;
		};
		
		public function $gte(a, b, c) {
			return traverse(a, c) >= b;
		};
		
		public function $lt(a, b, c) {
			return traverse(a, c) < b;
		};
		
		public function $lte(a, b, c) {
			return traverse(a, c) <= b;
		};
		
		public function $in(a, b, c) {
			var v = traverse(a, c);
			if(typeof(v) !== 'undefined') {
				var l = b.length;
				for(var i=0; i < l; i++) {
					if(b[i] == v) {
						return true;
					}
				}
			}
			return false;
		};
		
		public function $nin(a, b, c) {
			return !$in(a, b, c);
		};
		
		public function $or(a, b, c) {
			return traverse(a, b) !== undefined;
		};
		
		public function $sort(c, a, b) {
			switch(b) {
				case -1: // descending
					debug('$sort: descending, ' + a);
					c.sort(function(v1, v2){return v2[a] - v1[a];});
					break;
				
				case 0: // random
					debug('$sort: random, ' + a);
					shuffle(c);
					break;
				
				case 1: // ascending
					debug('$sort: ascending, ' + a);
					c.sort(function(v1, v2){return v1[a] - v2[a];});
					break;
				
				case 2: // alphabetically
					debug('$sort: alphabetically, ' + a);
					c.sort(function(v1, v2){ 
						if(v2[a] > v1[a]) {
							return -1;
						} else if(v2[a] < v1[a]) {
							return 1;
						} else {
							return 0;
						}
					});
					break;
				
				case 3: //  reverse
					debug('$sort: reverse, ' + a);
					c.sort(function(v1, v2){
						if(v2[a] < v1[a]) {
							return -1;
						} else if(v2[a] > v1[a]) {
							return 1;
						} else {
							return 0;
						}
					});
					break;
			}
		};
		
		public function $set(name, value, tuple, upsert) {
			var parts = truncatePath(name);
			if(parts === false) {
				$_upsert(name, value, tuple, upsert, false);
			} else {
				var stuple = traverse(parts[0], tuple);
				$_upsert(parts[1], value, stuple, upsert, false);
			}
		}
		
		public function $unset(name, value, tuple, upsert) {
			var parts = truncatePath(name);
			if(parts === false) {
				delete tuple[name];
			} else {
				var stuple = traverse(parts[0], tuple, false);
				delete stuple[name];
			}
		}
		
		public function $inc(name, value, tuple, upsert) {
			var parts = truncatePath(name);
			if(parts === false) {
				$_upsert(name, value, tuple, upsert, true);
			} else {
				var stuple = traverse(parts[0], tuple);
				$_upsert(parts[1], value, stuple, upsert, true);
			}
		}
		
		public function $_upsert(name, value, tuple, upsert, increment) {
			if(name in tuple) {
				if(increment) {
					tuple[name] += value;
				} else {
					tuple[name] = value;
				}
			} else {
				if(upsert) {
					tuple[name] = value;
				}
			}
		};
		
		
		/**
		 * Sets a flag signifying whether or not to log console debug output
		 * @param semaphor the flag signifying whether or not to log console debug output
		 * @return void
		 */
		public function debug(semaphor) {
			debug = semaphor;
		};
		
		/**
		 * Sets the file system path under which JSONDB will store and retrieve collection data. By default this is set to Titanium.Filesystem.applicationDataDirectory
		 * @param path the path to use when storing and retrieving collection data
		 * @return void
		 */
		public function storageLocation(path) {
			DEFAULT_FS_DIR = path;
		};
		
		/**
		 * Generates a random number between two numbers
		 * @param from the lower threshold of the range
		 * @param to the upper threshold of the range
		 */
		public function randomFromTo(from, to) {
			return Math.floor(Math.random() * (to - from + 1) + from);
		};
		
		/**
		 * Generates a BSON Object Identifier string
		 * @return string
		 */
		public function generateBSONIdentifier() {
			var ts = Math.floor( new Date().time/1000).toString(16);
			var hs = Titanium.Utils.md5HexDigest(Titanium.Platform.macaddress).substring(0, 6);
			var pid = randomFromTo(1000, 9999).toString(16);
			while(pid.length < 4) {
				pid = '0' + pid;
			}
			var inc = randomFromTo(100000, 999999).toString(16);
			while(inc.length < 6) {
				inc = '0' + inc;
			}
			return ts + hs + pid + inc;
		};
		
		/**
		 * Generates a struct in the same format as a MongoDate object
		 * @return object
		 */
		public function generateMongoDate() {
			var t =  new Date().time.toString();
			return {
				'sec': parseInt(t.substring(0, 10)),
				'usec': parseInt(t.substring(10))
			};
		};
		
		/**
		 * Truncates a given string path expression and returns an array containing the remaining path and the segment truncated
		 * @param path the string path expression
		 * @return array
		 */
		public function truncatePath(path) {
			if(path.match(/\./g) === null) {
				return false;
			}
			var chunks = path.split('.');
			var end = chunks.pop();
			return [chunks.join('.'), end]; 
		};
		
		/**
		 * Traverses an object and extracts a given parameter value corresponding to the provided string path
		 * @param path the object attribute path (e.g. "lat.lng")
		 * @param object the object to traverse
		 * @return mixed
		 */
		public function traverse(path, object) {
			if(path in tcache) {
				return tcache[path];
			}
			var t = function(p, o) {
				if(o === undefined) {
					return undefined;
				}
				if(p.length == 1) {
					return o[p.pop()];
				} else {
					var idx = p.shift();
					return t(p, o[idx]);
				}
			};
			tcache[path] = t(path.split('.'), object);
			return tcache[path];
		};
		
		/**
		 * Returns a normalized, JSON encoded string representation of an object
		 * @param o the object to serialize
		 * @return string
		 */
		public function stringify(o) {
			var clone = {};
			for(var key in o) {
				if(typeof(o[key]) == 'function') {
					clone[key] = o[key].toString();
				} else {
					clone[key] = o[key];
				}
			}
			return JSON.stringify(clone);
		};
		
		/**
		 * Randomizes the order of elements in an array
		 * @param c the array to randomize
		 * @return void
		 */
		public function shuffle(c) {
		    var tmp, current, top = c.length;
		    if(top) while(--top) {
		        current = Math.floor(Math.random() * (top + 1));
		        tmp = c[current];
		        c[current] = c[top];
		        c[top] = tmp;
		    }
		};
		
		/**
		 * Returns a count of the number of top level attributes in an object
		 * @param o the object to count
		 * @return integer
		 */
		public function sizeOf(o) {
		    var size = 0, key;
		    for (key in o) {
		        if (o.hasOwnProperty(key)) size++;
		    }
		    return size;
		};
		
		/**
		 * Sorts an object's keys alphabetically and returns a sorted, shallow copy of the object
		 * @param object the object to sort and clone
		 * @return object
		 */
		public function sortObjectKeys(object) {
			var o = {};
			var k = [];
			for(var key in object) {
				k.push(key);
			}
			k.sort(function(v1, v2){ 
				if(v2 > v1) {
					return -1;
				} else if(v2 < v1) {
					return 1;
				} else {
					return 0;
				}
			});
			k.forEach(function(i) {
				o[i] = object[i];
			});
			return o;
		};
		
		/**
		 * Generates an index name given an index definition and a flag signifying if it's a unique index. Index names take the form {attribute_name}{sort order}_{attribute_name}{sort_order}+{type}.
		 * For example the index name for definition [x:-1,y:1],false would be x-1_y1+s (where +s identifies the index as "sparse" rather than "unique".
		 * @param o the index definition
		 * @param unique a flag signifying whether the index is sparse or unique
		 * @return string
		 */
		public function generateIndexName(o, unique) {
			var n = [];
			for(var k in o) {
				if(k == $or) {
					continue;
				}
				n.push(k);
			}
			if(unique == undefined) {
				return n.join('_');
			}
			return n.join('_') + '+' + ((unique == true) ? 'u' : 's');
		};
		
		/**
		 * Performs a deep clone of an object, returning a pointer to the clone
		 * @param o the object to clone
		 * @return object
		 */
		public function cloneObject(o) {
			var c = {};
			for(var a in o) {
				if(typeof(o[a]) == "object") {
					c[a] = cloneObject(o[a]);
				} else {
					c[a] = o[a];
				}
			}
			return c;
		}; 
		
	}
}