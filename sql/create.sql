CREATE TABLE students (
	id	TEXT PRIMARY KEY,
	fprint	TEXT NOT NULL,
	emoji	TEXT NOT NULL,
	text	TEXT NOT NULL,
	nick	TEXT,
	course	TEXT NOT NULL,
	section INTEGER NOT NULL
);
