package Libs
{
	import mx.utils.SHA256;

	/**
	 * The file system I/O manager for JSONDB collections
	 * @constructor
	 */
	public class FilesystemManager extends JsonDB
	{
		public function FilesystemManager()
		{
		}
		
		/**
		 * Loads a JSONDB collection from disk
		 * @param filename the name of the collection file to load
		 * @param secret the secret to use when signing collection data
		 * @param path the file system path to save to
		 * @return object/boolean
		 */
		public function load(filename, secret, path) {
			if(path == undefined) {
				path = DEFAULT_FS_DIR;
			}
			filename += '.json';
			var file = Titanium.Filesystem.getFile(path, filename);
			if (file.exists()) {
				var data = JSON.parse(file.read());
				if(CryptoProvider.verifySignature(data, secret, data._salt) == false) {
					Ti.App.fireEvent("JSONDBDataTampered", {filename:filename});
					return false;
				}
				delete data.sig;
				return data;
			}			
			return false;
		};
		
		/**
		 * Saves a JSONDB collection to disk
		 * @param filename the name of the collection file to save to
		 * @param data the data to save to disk
		 * @param secret the secret to use when signing collection data
		 * @param path the file system path to save to
		 * @return boolean
		 */
		public function save(filename, data, secret, path) {
			filename += '.json';
			if(path == undefined) {
				path = DEFAULT_FS_DIR;
			}		
			if(data._salt == null) {
				data._salt = Ti.Utils.sha1( new Date().time + "");
			}
			data._sig = CryptoProvider.signData(data, secret, data._salt);
			var file = Titanium.Filesystem.getFile(path, filename);
			file.write(JSON.stringify(data));
			return true;
		};		
		
	};
}