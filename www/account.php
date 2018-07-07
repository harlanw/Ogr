<?php

require_once('config.php');
require_once('crypto.php');

abstract class Account
{
	public static function from_hash($key, $hash64, $regex, &$user)
	{
		$status = false;

		$data = Crypto::decrypt($key, $hash64);
		if ($data != NULL)
		{
			$found = preg_match("/known,($regex),([0-9]+),value/", $data, $matches);

			// Expected matches: original string + id + section (3)
			if (count($matches) == 3)
			{
				$status = true;

				$hash16 = strtoupper(bin2hex(base64_decode($hash64)));

				$user = [
					'id'      => $matches[1],
					'section' => $matches[2],
					'hash64'  => $hash64,
					'hash16'  => $hash16
				];
			}
		}

		return $status;
	}
}
