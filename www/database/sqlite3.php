<?php

class Database
{
	const SQL_LOOKUP_USER = "SELECT * FROM students WHERE id = :id";

	private $handle = NULL;
	private $err_str = NULL;

	public function __construct($file)
	{
		$handle = new PDO("sqlite:$file");
		$handle->setAttribute(PDO::ATTR_ERRMODE,
			PDO::ERRMODE_EXCEPTION);
		$handle->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE,
			PDO::FETCH_ASSOC);

		$this->handle = $handle;
	}

	public function lookup($user)
	{
		$result = NULL;

		if ($this->handle == NULL)
			return NULL;

		try
		{
			$query = $this->handle->prepare(self::SQL_LOOKUP_USER);
			$query->bindParam(":id", $user);
			$query->execute();

			$result = $query->fetch();
		}
		catch (PDOException $e)
		{
			$err_str = $e->getMessage();
		}

		return $result;
	}

}
