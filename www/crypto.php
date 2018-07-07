<?php

abstract class Crypto
{
	public static function encrypt($key, $text)
	{
		$ivlen = openssl_cipher_iv_length($cipher='AES-256-CBC');
		$iv    = openssl_random_pseudo_bytes($ivlen);
		$raw   = openssl_encrypt($text, $cipher, $key, $options=OPENSSL_RAW_DATA, $iv);
		$hmac  = hash_hmac('sha256', $raw, $key, $as_binary=true);

		return base64_encode($iv . $hmac . $raw);
	}

	public static function decrypt($key, $hash64)
	{
		$data  = base64_decode($hash64);
		$ivlen = openssl_cipher_iv_length($cipher='aes-256-cbc');
		$iv    = substr($data, 0, $ivlen);
		$hmac  = substr($data, $ivlen, $sha2len=32);
		$raw   = substr($data, $ivlen + $sha2len);
		$text  = openssl_decrypt($raw, $cipher, $key, $options=OPENSSL_RAW_DATA, $iv);

		$chk_hmac =  hash_hmac('sha256', $raw, $key, $as_binary=true);

		if (hash_equals($hmac, $chk_hmac) == false)
			$text = NULL;

		return $text;
	}
}

?>
