package Libs
{
	/**
	 * Provides cryptography utility functions for JSONDB collections
	 * @constructor
	 */
	public class CryptoProvider extends JsonDB
	{
		/**
		 * Generates a signature given a string
		 * @param string the string to sign
		 * @param secret the secret to use when calculating a signature
		 * @param salt the secret to use when calculating a signature
		 * @return string
		 */
		public function generateSignature(string, secret, salt) {
			return Ti.Utils.sha1(Ti.Utils.sha1(string + secret) + salt);
		};	
		
		/**
		 * Signs a JavaScript object
		 * @param data the data to sign
		 * @param secret the secret to use when calculating a signature
		 * @param salt the secret to use when calculating a signature
		 * @return string
		 */
		public function signData(data, secret, salt) {
			data._sig = salt;
			return this.generateSignature(JSON.stringify(data), secret, salt);
		};
		
		/**
		 * Verifies the signature provided as part of a JavaScript object against a calculated signature
		 * @param data the data to verify
		 * @param secret the secret to use when calculating a signature
		 * @param salt the secret to use when calculating a signature
		 * @return boolean
		 */
		public function verifySignature(data, secret, salt) {
			var oldSig = data._sig;
			var newSig = this.signData(data, secret, salt);
			return  newSig == oldSig;
		}
		
		/**
		 * Generates a signature for a JSON encoded string
		 * @param data the data to sign
		 * @param secret the secret to use when calculating a signature
		 * @param salt the secret to use when calculating a signature
		 * @return string
		 */
		public function signJson(data, secret, salt) {
			return this.generateSignature(JSON.stringify(data), secret, salt);
		}
		
	}
}