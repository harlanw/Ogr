<?php

require_once('cookie.php');
require_once('crypto.php');
require_once('account.php');
require_once('database/sqlite3.php');

abstract class Gradebook
{
	public static function deny($domain, $path, $reason)
	{
		Cookie::destroy('_auth', $domain, $path);
		Cookie::destroy('_identity', $domain, $path);
		Cookie::destroy('_emoji', $domain, $path);
		Cookie::destroy('_text', $domain, $path);

		header("Location: https://$domain/$path?denied&reason=$reason");
		exit();
	}

	protected static function begin_handshake($to, $from)
	{
		header("Location: $to/login?service=$from");
		exit();
	}

	protected static function verify($to, $from, $ticket)
	{
		$result = NULL;

		$req = "$to/serviceValidate?ticket=$ticket&service=$from";
		$xml = file_get_contents($req);

		if (preg_match('/cas:authenticationSuccess/', $xml))
		{
			$array = preg_split('/\n/', $xml);
			$search = preg_grep("/($regex)<\/cas:user>/", $array);
			if (is_array($search) == true)
			{
				$result = trim(strip_tags(implode($search)));
			}
		}

		return $result;
	}

	public static function login($config, &$user)
	{
		$success = false;

		$key = $config['key'];

		$server = $config['server'];
		$domain = $config['domain'];
		$path   = $config['path'];
		$days   = $config['days'];
		$regex  = $config['regex'];

		$database = $config['database'];

		// Capture current URL so that CAS can return to this location
		$uri = strtok($_SERVER['REQUEST_URI'], '?');
		$url = "https://$domain$uri";

		$auth = $_COOKIE['_auth'];

		if (/*(isset($auth) == false) && */($ticket = $_GET['ticket']))
		{
			$onid = Gradebook::verify($server, $url, $ticket);
			if ($onid != NULL)
			{
				$db = new Database($database);
				$user = $db->lookup($onid);

				if ($user != NULL)
				{
					$success = true;

					// Critical account data is hashed along with a known string and stored as a
					// cookie. The purpose of this string ("known,...,value") is to make it
					// difficult for users to change their onid.
					//
					// Originally, the technique described within the encryption function was
					// used to prevent this, but it was trivial to generate new hashes that
					// would slightly change the ONID while still satisfying the verification
					// technique (HMAC step). The resulting security level is sufficient at this
					// time since it is not beneficial for class members to change their ONID.
					//
					// TODO: Use GRADEBOOK_KEY to generate unique hashes per-student to improve
					// hashing security.

					$hash64 = Crypto::encrypt($key, "known,$user[id],$user[section],value");

					// One-time cookie used to identify users
					Cookie::create('_auth', $hash64, $days, $domain, $path);

					// Purely cosmetic values
					Cookie::create('_emoji', $user['emoji'], $days, $domain, $path);
					Cookie::create('_text', $user['text'], $days, $domain, $path);
					// Set user identity to FPRINT (or NICK if it exists)
					$identity = $user['fprint'];
					if (isset($user['nick']) != NULL)
					{
						$identity = $user['nick'];
					}
					Cookie::create('_identity', $identity, $days, $domain, $path);

					header("Location: $url?success");
					exit();
				}
			}
			else
			{
				Gradebook::deny($domain, $path, "BAD_TICKET");
			}
		}
		else if (Account::from_hash($key, $auth, $regex, $user) == false)
		{
			Gradebook::begin_handshake($server, $url);
		}
		else
		{
			$success = true;
		}

		return $success;
	}
}
