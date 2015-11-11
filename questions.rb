require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true
    self.type_translation = true
  end
end

class Question

  attr_accessor :id, :title, :body, :author_id

  def initialize(options)
    @id, @title, @body, @author_id = options.values_at('id', 'title', 'body', 'author_id')
  end

  def self.find_by_id(lookup_id)
    row = QuestionsDatabase.instance.execute(<<-SQL, lookup_id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    Question.new(row.first)
  end

  def self.find_by_author_id(author_id)
    rows = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    rows.map { |row| Question.new(row) }
  end

  def author
    rows = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        fname, lname
      FROM
        users
      WHERE
        id = ?
    SQL
    rows.first['fname'] + ' ' + rows.first['lname']
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollow.followers_for_question_id(id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def save
    if id
      update
    else
      create
    end
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, id: id, title: title, body: body, author_id: author_id)
      UPDATE
        questions
      SET
        title = :title, body = :body, author_id = :author_id
      WHERE
        id = :id
    SQL
  end

  def create
    QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id)
      INSERT INTO
        questions (title, body, author_id)
      VALUES
        (?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end

class User

  attr_accessor :id, :fname, :lname

  def initialize(options)
    @id, @fname, @lname = options.values_at('id', 'fname', 'lname')
  end

  def self.find_by_id(lookup_id)
    row = QuestionsDatabase.instance.execute(<<-SQL, lookup_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    User.new(row.first)
  end

  def self.find_by_name(fname, lname)
    rows = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    User.new(rows.first)
  end

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_user_id(id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(id)
  end

  def average_karma
    rows = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        CAST(COUNT(ql.user_id) as FLOAT) / COUNT(DISTINCT(q.id))
      FROM
        questions q
      LEFT OUTER JOIN
        question_likes ql ON q.id = ql.question_id
      INNER JOIN
        users u ON u.id = q.author_id
      WHERE
        u.id = ?
    SQL
    rows.first.values.first
  end

  def save
    if id
      update
    else
      create
    end
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, id: id, fname: fname, lname: lname)
      UPDATE
        users
      SET
        fname = :fname, lname = :lname
      WHERE
        id = :id
    SQL
  end

  def create
    QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end

class Reply
  attr_accessor :id, :question_id, :parent_id, :replier_id, :body

  def initialize(options)
    @id, @question_id, @parent_id, @replier_id, @body =
      options.values_at('id', 'question_id', 'parent_id', 'replier_id', 'body')
  end

  def self.find_by_user_id(user_id)
    rows = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replier_id = ?
    SQL
    rows.map { |row| Reply.new(row) }
  end

  def self.find_by_question_id(question_id)
    rows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    rows.map { |row| Reply.new(row) }
  end

  def author
    rows = QuestionsDatabase.instance.execute(<<-SQL, replier_id)
      SELECT
        fname, lname
      FROM
        users
      WHERE
        id = ?
    SQL
    rows.first['fname'] + ' ' + rows.first['lname']
  end

  def question
    rows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        title, body
      FROM
        questions
      WHERE
        id = ?
    SQL
    rows.first
  end

  def parent_reply
    rows = QuestionsDatabase.instance.execute(<<-SQL, parent_id)
      SELECT
        body
      FROM
        replies
      WHERE
        id = ?
    SQL
    rows.first
  end

  def child_replies
    rows = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        body
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    rows.first
  end

  def save
    if id
      update
    else
      create
    end
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, id: id, question_id: question_id, parent_id: parent_id, replier_id: replier_id, body: body)
      UPDATE
        replies
      SET
        question_id = :question_id, parent_id = :parent_id, replier_id = :replier_id, body = :body
      WHERE
        id = :id
    SQL
  end

  def create
    QuestionsDatabase.instance.execute(<<-SQL, question_id, parent_id, replier_id, body)
      INSERT INTO
        replies (question_id, parent_id, replier_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end

class QuestionFollow
  attr_accessor :id, :user_id, :question_id

  def initialize(options)
    @id, @user_id, @question_id =
      options.values_at('id', 'user_id', 'question_id')
  end

  def self.followers_for_question_id(question_id)
    rows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        fname, lname, u.id
      FROM
        users u
      INNER JOIN
        question_follows qf ON u.id = qf.user_id
      WHERE
        qf.question_id = ?
    SQL

    rows.map { |row| User.new(row) }
  end

  def self.followed_questions_for_user_id(user_id)
    rows = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions q
      WHERE
        q.id IN (
          SELECT
            question_id
          FROM
            question_follows
          WHERE
            user_id = ?
        )
    SQL
    rows.map { |row| Question.new(row) }
  end

  def self.most_followed_questions(n)
    rows = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        q.id, title, body, author_id
      FROM
        questions q
      INNER JOIN
        question_follows qf
      ON
        q.id = qf.question_id
      GROUP BY
        qf.user_id
      ORDER BY
        COUNT(qf.user_id) DESC
      LIMIT ?

    SQL
    rows.map { |row| Question.new(row) }
  end

end

class QuestionLike
    attr_accessor :id, :question_id, :user_id

    def initialize(options)
      @id, @question_id, @user_id = options.values_at('id', 'question_id', 'user_id')
    end

    def self.likers_for_question_id(question_id)
      rows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
          u.id, fname, lname
        FROM
          question_likes ql
        INNER JOIN
          users u
        ON
          u.id = ql.user_id
        WHERE
          question_id = ?
      SQL
      rows.map { |row| User.new(row) }
    end

    def self.num_likes_for_question_id(question_id)
      rows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
          COUNT(user_id)
        FROM
          question_likes
        WHERE
          question_id = ?
        GROUP BY
          question_id
      SQL
      rows.first.values.first
    end

    def self.liked_questions_for_user_id(user_id)
      rows = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
          q.id, q.author_id, q.title, q.body
        FROM
          questions q
        JOIN
          question_likes ql
        ON
          q.id = ql.question_id
        WHERE
          ql.user_id = ?
      SQL
      rows.map { |row| Question.new(row) }
    end

    def self.most_liked_questions(n)
      rows = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
          q.id, title, body, author_id
        FROM
          questions q
        INNER JOIN
          question_likes ql
        ON
          q.id = ql.question_id
        GROUP BY
          ql.user_id
        ORDER BY
          COUNT(ql.user_id) DESC
        LIMIT ?
      SQL
      rows.map { |row| Question.new(row) }
    end
end
