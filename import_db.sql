DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS questions;
CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES author(id)
);

DROP TABLE IF EXISTS question_follows;
CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;
CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  replier_id INTEGER NOT NULL,
  body VARCHAR(255),

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (replier_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;
CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Tracy', 'Mullen'),
  ('Claire', 'Rogers');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('I have a question', 'Please answer my question', (SELECT id FROM users WHERE fname = 'Tracy')),
  ('I have a better questions', 'ANSWER NOW!!!!', (SELECT id FROM users WHERE lname = 'Rogers')),
  ('??', 'Ahhh...', (SELECT id FROM users WHERE fname = 'Tracy')),
  ('Help me!!', '...........', (SELECT id FROM users WHERE fname = 'Claire'));


INSERT INTO
  replies (question_id, parent_id, replier_id, body)
VALUES
  (1, NULL, 2, "NEVER! google it :)"),
  (1, 1, 1, "I DID! You suck lol");


INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (2, 1),
  (1, 1),
  (1, 2);

INSERT INTO
  question_likes (question_id, user_id)
VALUES
  (2, 1),
  (2, 2),
  (1, 1);
