
/*
 +------------------------------------------------------------------------+
 | Phalcon Framework                                                      |
 +------------------------------------------------------------------------+
 | Copyright (c) 2011-2017 Phalcon Team (https://phalconphp.com)          |
 +------------------------------------------------------------------------+
 | This source file is subject to the New BSD License that is bundled     |
 | with this package in the file LICENSE.txt.                             |
 |                                                                        |
 | If you did not receive a copy of the license and are unable to         |
 | obtain it through the world-wide-web, please send an email             |
 | to license@phalconphp.com so we can send you a copy immediately.       |
 +------------------------------------------------------------------------+
 | Authors: Andres Gutierrez <andres@phalconphp.com>                      |
 |          Eduar Carvajal <eduar@phalconphp.com>                         |
 +------------------------------------------------------------------------+
 */

namespace Phalcon\Cache\Backend;

use Phalcon\Cache\Backend;
use Phalcon\Cache\Exception;
use Phalcon\Cache\FrontendInterface;

/**
 * Phalcon\Cache\Backend\Redis
 *
 * Allows to cache output fragments, PHP data or raw data to a redis backend
 *
 *<code>
 * use Phalcon\Cache\Backend\Redis;
 * use Phalcon\Cache\Frontend\Data as FrontData;
 *
 * // Cache data for 2 days
 * $frontCache = new FrontData(
 *     [
 *         "lifetime" => 172800,
 *     ]
 * );
 *
 * // Create the Cache setting redis connection options
 * $cache = new Redis(
 *     $frontCache,
 *     [
 *         "host"       => "localhost",
 *         "port"       => 6379,
 *         "auth"       => "foobared",
 *         "persistent" => false,
 *         "index"      => 0,
 *     ]
 * );
 *
 * // Cache arbitrary data
 * $cache->save("my-data", [1, 2, 3, 4, 5]);
 *
 * // Get data
 * $data = $cache->get("my-data");
 *</code>
 */
class Redis extends Backend
{
	protected _redis = null;

	/**
	 * Phalcon\Cache\Backend\Redis constructor
	 *
	 * @param	Phalcon\Cache\FrontendInterface frontend
	 * @param	array options
	 */
	public function __construct(<FrontendInterface> frontend, options = null)
	{
		if typeof options != "array" {
			let options = [];
		}

		if !isset options["host"] {
			let options["host"] = "127.0.0.1";
		}

		if !isset options["port"] {
			let options["port"] = 6379;
		}

		if !isset options["index"] {
			let options["index"] = 0;
		}

		if !isset options["persistent"] {
			let options["persistent"] = false;
		}

		if !isset options["statsKey"] {
			// Disable tracking of cached keys per default
			let options["statsKey"] = "";
		}

		if !isset options["auth"] {
			let options["auth"] = "";
		}
		if !isset options["timeout"] {
			let options["timeout"] = 0;
		}
		parent::__construct(frontend, options);
	}

	/**
	 * Create internal connection to redis
	 */
	public function _connect()
	{
		var options, redis, persistent, success, host, port, auth, index, timeout;

		let options = this->_options;
		let redis = new \Redis();

		if !fetch host, options["host"] || !fetch port, options["port"] || !fetch persistent, options["persistent"] || !fetch timeout, options["timeout"] {
			throw new Exception("Unexpected inconsistency in options");
		}

		if persistent {
			let success = redis->pconnect(host, port, timeout);
		} else {
			let success = redis->connect(host, port, timeout);
		}

		if !success {
			throw new Exception("Could not connect to the Redisd server ".host.":".port);
		}

		if fetch auth, options["auth"] && !empty options["auth"] {
			let success = redis->auth(auth);

			if !success {
				throw new Exception("Failed to authenticate with the Redisd server");
			}
		}

		if fetch index, options["index"] && index > 0 {
			let success = redis->select(index);

			if !success {
				throw new Exception("Redis server selected database failed");
			}
		}

		let this->_redis = redis;
	}

	/**
	 * Returns a cached content
	 */
	public function get(string keyName, int lifetime = null) -> var | null
	{
		var redis, frontend, lastKey, cachedContent;

		let redis          = this->getClient();
		let frontend       = this->_frontend;
		let lastKey        = this->getStoreKey(keyName);
		let this->_lastKey = lastKey;
		let cachedContent  = redis->get(lastKey);

		if cachedContent === false {
			return null;
		}

		if is_numeric(cachedContent) {
			return cachedContent;
		}

		return frontend->afterRetrieve(cachedContent);
	}

	/**
	 * Stores cached content into the file backend and stops the frontend
	 *
	 * <code>
	 * $cache->save("my-key", $data);
	 *
	 * // Save data termlessly
	 * $cache->save("my-key", $data, -1);
	 * </code>
	 *
	 * @param int|string keyName
	 * @param string content
	 * @param int lifetime
	 * @param boolean stopBuffer
	 */
	public function save(keyName = null, content = null, lifetime = null, boolean stopBuffer = true) -> boolean
	{
		var prefixedKey, lastKey, frontend, redis, cachedContent, preparedContent,
			tt1, success, isBuffering;

		if keyName === null {
			let lastKey     = this->_lastKey,
				prefixedKey = substr(lastKey, 5);
		} else {
			let prefixedKey    = this->getPrefixedKey(keyName),
				lastKey        = this->getStoreKey(keyName),
				this->_lastKey = lastKey;
		}

		if !lastKey {
			throw new Exception("The cache must be started first");
		}

		let frontend = this->_frontend;

		/**
		 * Check if a connection is created or make a new one
		 */
		let redis = this->getClient();

		if content === null {
			let cachedContent = frontend->getContent();
		} else {
			let cachedContent = content;
		}

		/**
		 * Prepare the content in the frontend
		 */
		if !is_numeric(cachedContent) {
			let preparedContent = frontend->beforeStore(cachedContent);
		} else {
			let preparedContent = cachedContent;
		}

		if lifetime === null {
			if !this->_lastLifetime {
				let tt1 = frontend->getLifetime();
			} else {
				let tt1 = this->_lastLifetime;
			}
		} else {
			let tt1 = lifetime;
		}

		let success = redis->set(lastKey, preparedContent);

		if !success {
			throw new Exception("Failed storing the data in redis");
		}

		// Don't set expiration for negative ttl or zero
		if tt1 >= 1 {
			redis->setTimeout(lastKey, tt1);
		}

		if this->getSpecialKey() != "" {
			redis->sAdd(specialKey, prefixedKey);
		}

		let isBuffering = frontend->isBuffering();

		if stopBuffer === true {
			frontend->stop();
		}

		if isBuffering === true {
			echo cachedContent;
		}

		let this->_started = false;

		return success;
	}

	/**
	 * Deletes a value from the cache by its key
	 *
	 * @param int|string keyName
	 */
	public function delete(keyName) -> boolean
	{
		var redis, prefixedKey, lastKey, options, specialKey;

		let redis       = this->getClient(),
			prefixedKey = this->getPrefixedKey(keyName),
			lastKey     = this->getStoreKey(keyName);
		let options     = this->_options;

		if this->getSpecialKey() != "" {
			redis->sRem(specialKey, prefixedKey);
		}

		/**
		* Delete the key from redis
		*/
		return (bool) redis->delete(lastKey);
	}

	/**
	 * Query the existing cached keys.
	 *
	 * <code>
	 * $cache->save("users-ids", [1, 2, 3]);
	 * $cache->save("projects-ids", [4, 5, 6]);
	 *
	 * var_dump($cache->queryKeys("users")); // ["users-ids"]
	 * </code>
	 */
	public function queryKeys(string prefix = null) -> array
	{
		var redis, options, keys, specialKey, key, idx;

		let redis   = this->getClient();
		let options = this->_options;

		if !fetch specialKey, options["statsKey"] {
			throw new Exception("Unexpected inconsistency in options");
		}

		if specialKey == "" {
			throw new Exception("Cached keys need to be enabled to use this function (options['statsKey'] == '_PHCR')!");
		}

		/**
		* Get the key from redis
		*/
		let keys = redis->sMembers(specialKey);
		if typeof keys != "array" {
			return [];
		}

		for idx, key in keys {
			if !empty prefix && !starts_with(key, prefix) {
				unset keys[idx];
			}
		}

		return keys;
	}

	/**
	 * Checks if cache exists and it isn't expired
	 *
	 * @param string keyName
	 * @param int lifetime
	 */
	public function exists(keyName = null, lifetime = null) -> boolean
	{
		var lastKey, redis;

		if !keyName {
			let lastKey = this->_lastKey;
		} else {
			let lastKey = this->getStoreKey(keyName);
		}

		if lastKey {
			let redis = this->getClient();

			return (bool) redis->exists(lastKey);
		}

		return false;
	}

	/**
	 * Increment of given $keyName by $value
	 *
	 * @param string keyName
	 */
	public function increment(keyName = null, int value = 1) -> int
	{
		var redis, lastKey;

		let redis = this->getClient();

		if !keyName {
			let lastKey = this->_lastKey;
		} else {
			let lastKey        = this->getStoreKey(keyName),
				this->_lastKey = lastKey;
		}

		return redis->incrBy(lastKey, value);
	}

	/**
	 * Decrement of $keyName by given $value
	 *
	 * @param string keyName
	 */
	public function decrement(keyName = null, int value = 1) -> int
	{
		var redis, lastKey;

		let redis = this->getClient();

		if !keyName {
			let lastKey = this->_lastKey;
		} else {
			let lastKey        = this->getStoreKey(keyName),
				this->_lastKey = lastKey;
		}

		return redis->decrBy(lastKey, value);
	}

	/**
	 * Immediately invalidates all existing items.
	 */
	public function flush() -> boolean
	{
		var options, specialKey, redis, keys, key, lastKey;

		let options = this->_options;

		if !fetch specialKey, options["statsKey"] {
			throw new Exception("Unexpected inconsistency in options");
		}

		if specialKey == "" {
			throw new Exception("Cached keys need to be enabled to use this function (options['statsKey'] == '_PHCR')!");
		}

		let redis = this->getClient();
		let keys = redis->sMembers(specialKey);
		if typeof keys == "array" {
			for key in keys {
				let lastKey = this->getPrefixedKey(keyName);
				redis->sRem(specialKey, key);
				redis->delete(lastKey);
			}
		}

		return true;
	}

	/**
	 * Returns the Redis client. Connects if not set
	 */
	private function getClient() -> <\Redis>
	{
		if typeof this->_redis != "object" {
			this->_connect();
		}

		return this->_redis;
	}

	/**
	 * Returns the key with its prefix
	 */
	private function getPrefixedKey(string keyName) -> string
	{
		return this->_prefix . keyName;
	}

	/**
	 * Returns the special key if set; empty string otherwise
	 */
	private function getSpecialKey() -> string
	{
		var specialKey;

		if fetch specialKey, this->_options["statsKey"] {
			return specialKey;
		}

		return "";
	}

	/**
	 * Returns the store key with the special key and prefix
	 */
	private function getStoreKey(string keyName) -> string
	{
		string specialKey;

		if fetch specialKey, options["statsKey"] {
			let specialKey = (string) specialKey;
		} else {
			let specialKey = "";
		}

		return specialKey . this->getPrefixedKey(keyName);
	}
}