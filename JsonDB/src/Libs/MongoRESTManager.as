package Libs
{
	public class MongoRESTManager extends JsonDB
	{
		protected var _name;
		protected var _db = null;
		protected var _cn = null;
		protected var _host;
		protected var _key;
		protected var _query;
		protected var _base;
		
		public function MongoRESTManager(name, host, key, query) {
			_name = name;
			_host = host;
			_key = key;
			_query = query;
			_base =  = 'https://' + _host + '/api/1'
			
			if(host == undefined) {
				host = DEFAULT_API_HOST;
			}
			
			if(_name.match(/\:/) == null) {
				throw 'badly formed collection identified, please use the format database:collection';
			}
			var c = _name.split(':', 2);
			_db = c[0];
			._cn = c[1];
			super();
		}
		
		
		/**
		 * The JSONDB MongoLab REST API connector
		 * @constructor
		 * @param name the name of the collection to connect to
		 * @param host the API host name to connect to
		 * @param key the API access key to use when performing HTTP requests
		 * @param query the query object to use when loading objects from the MongoDB collection
		 */
		
			
			
			
			/**
			 * Loads objects from the MongoDB collection
			 * @param collection the JSONDB collection struct to load objects into
			 * @return void
			 */
			public function load(collection) {
				
				var u = _base + '/databases/' + _db + '/collections/' + _cn + '?apiKey=' + _key;
				if(_query != undefined) {
					u += '&q=' + JSON.stringify(_query);
				}
				
				var _t = this;
				
				var xhr = Titanium.Network.createHTTPClient();
				xhr.onerror = function(e) {
					Ti.App.fireEvent('JSONDBDownloadError', {error: e.error});
				};
				
				xhr.onload = function(e) {
					var t = this;
					if(status != 200) {
						Ti.App.fireEvent('JSONDBDownloadError', {error: e.error, response: t.responseText});
						return;
					}
					var o = JSON.parse(responseData);
					o.forEach(function(object) {
						object.$id = object._id.$oid;
						delete object._id;
						collection._objects[object.$id] = object; 
					});
					Ti.App.fireEvent('JSONDBDownloadSuccess', {collection_name: _t._cn});
				};
				
				xhr.open('GET', u);
				xhr.send()
				
			};
			
			/**
			 * Saves JSONDB collection data to the MongoLab REST API
			 * @param collection the collection of objects to send
			 * @return void
			 */
			public function save(collection) {
				
				var u = _base + '/databases/' + _db + '/collections/' + _cn + '?apiKey=' + _key;
				var _t = this;
				
				var xhr = Titanium.Network.createHTTPClient();
				xhr.validatesSecureCertificate = false;
				xhr.onreadystatechange = function() {};
				xhr.timeout = 30000;
				
				xhr.onerror = function(e) {
					Ti.App.fireEvent('JSONDBUploadError', {error: e.error});
				};
				
				xhr.onload = function(e) {
					var t = this;
					if(status != 200) {
						Ti.App.fireEvent('JSONDBUploadError', {response: t.responseText, status: t.status});
						return;
					}
					Ti.App.fireEvent('JSONDBUploadSuccess', {response: t.responseText, status: t.status});
					_t._deleteDocuments();
				};
				
				var o = [];
				var obj = null;
				for(var k in collection._objects) {
					obj = cloneObject(collection._objects[k]);
					_normalizeObjectIds(obj);
					o.push(obj);
				}
				
				xhr.open('PUT', u);
				xhr.setRequestHeader("Content-Type", "application/json");		
				xhr.send(JSON.stringify(o));
				
			};
			
			protected function _normalizeObjectIds(o) {
				for(var k in o) {
					if(k == ID_FIELD) {
						if(REF_FIELD in o) {
							o.$id = {$oid: o.$id};
							o.$ref = _cn;
						} else {
							o._id = {$oid: o.$id};
							delete o.$id;
						}
					} else {
						if(typeof(o[k]) == 'object') {
							_normalizeObjectIds(o[k]);
						}
					}
				}
			};
			
			protected function _deleteDocuments() {
				
				if(_name.match(/\:/) == null) {
					throw 'badly formed collection identified, please use the format database:collection';
				}
				
				var c = _name.split(':', 2);
				var u = _base + '/databases/' + c[0] + '/collections/' + c[1];				
				var k = _key;
				var o = Log.find({cl:_name, cm:'delete'});
				
				o.forEach(function(d) {
					
					var url = u + '/' + d.$id + '?apiKey=' + k;
					
					var xhr = Titanium.Network.createHTTPClient();
					xhr.validatesSecureCertificate = false;
					xhr.timeout = 30000;
					
					xhr.onerror = function(e) {
						Ti.App.fireEvent('JSONDBDeleteError', {error: e.error});
					};
					
					xhr.onload = function(e) {
						var t = this;
						if(this.status != 200) {
							Ti.App.fireEvent('JSONDBDeleteError', {error: e.error, response: t.responseText, status: t.status});
							return;
						}
						Log.remove({$id:d.$id});
						Log.commit();
						Ti.App.fireEvent('JSONDBDeleteSuccess', {o: o, response: t.responseText, status: t.status});
					};
					
					xhr.open('DELETE', url);
					xhr.send();
					
				});
				
			};
			
		}
	}
}