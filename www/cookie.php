<?php

abstract class Cookie
{
	public static function create($name, $value, $days, $domain, $path)
	{
		$url = "https://$domain/$path";
		$expires = time() + (86400 * $days);

		setcookie($name, $value, $expires, $path, $domain, true);
	}

	public static function destroy($name, $domain, $path)
	{
		unset($_COOKIE[$name]);
		setcookie($name, null, -1, $path, $domain, 1);
	}
}
