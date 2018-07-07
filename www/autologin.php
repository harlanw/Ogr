<?php

require_once('config.php');
require_once('gradebook.php');

if (Gradebook::login(AUTH, $user) == false)
{
	// Verification will only return false if there is an infrastructure problem (CAS/DB). This is
	// because a bad hash will simply retrigger the handshake before exiting the script. The other
	// conditions all deal with remote authorization.
	//
	// For this reason it doesn't make sense to automatically retry since it is likely that it will
	// fail again.
	
	Gradebook::deny(AUTH['domain'], AUTH['path'], "AUTH_FAILURE");
}
