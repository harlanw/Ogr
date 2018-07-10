<?php

const UNICODE_COOKIE = '&#x1F36A;';

if (isset($_GET['peek']) == false)
{
	require_once('autologin.php');

	// These cookies hold purely cosmetic information and can be overwritten by the user
	$emoji = $_COOKIE['_emoji'];
	$ident = $_COOKIE['_identity'];
	$text   = $_COOKIE['_text'];
}
else
{
	$emoji = UNICODE_COOKIE;
	$text   = 'cookie';
	$ident = 'FFFFFF';

	$user = [
		'id'   => 'demo_user',
		'hash64' => 'VW5saWtlIHRoaXMgb25lLCBhIHJlYWwgYmFzZTY0IGZpbmdlcnByaW50IHNpZ25zIHlvdXIgc2Vzc2lvbiB3aXRoIGEgcHJpdmF0ZSBrZXkuCg==',
		'hash16' => '566C6331633246586447784A53464A765956684E5A3249794E57784D51304A6F5355684B62466C586432645A62555A36576C525A4D456C48576E42696257527359323543655746584E54424A53453577'
	];
}

// Easter egg for users who delete a non-secure cookie (cookies that only effect
// the user interface).
if (!isset($emoji) || !isset($text) || !isset($ident))
{
	$emoji = UNICODE_COOKIE;
	$text = '!';
	$ident = "you aren't supposed to eat these";
}

// https://$domain/$path/?redact => Hide user information
if (isset($_GET['redact']) == true)
{
	$emoji = '&cross;';
	$style = "class='redact' style='color: #121212; background-color: #121212;'";
}

$html = "
<section id='whoami' class='row'>
	<div id='emoji' title='$text'>
		<span>$emoji</span>
	</div>
	<div id='account' class='col'>
		<b>whoami:</b> $user[id]</span><br>
		<hr>
		<b>base64:</b> <span $style>$user[hash64]</span><br>
		<b>base16:</b> <span $style>$user[hash16]</span><br>
		<b>fprint:</b> <span $style>$ident</span> (<span $style>$text</span>)<br>
		<hr>
	</div>
</section>";

echo $html;

?>
