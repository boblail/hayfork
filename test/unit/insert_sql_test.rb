require "test_helper"

class InsertSqlTest < Minitest::Test
  attr_reader :haystack, :relation, :bindings


  context "#to_sql" do
    context "in the general case" do
      setup do
        @relation = Book.all
        @bindings = [
          Binding(Hayfork::SEARCH_RESULT_TYPE, "Book"),
          Binding(Hayfork::SEARCH_RESULT_ID, Book.arel_table[:id]),
          Binding(Hayfork::TEXT, Book.arel_table[:title]),
          Binding(Hayfork::SEARCH_VECTOR, Book.arel_table[:title])
        ]
      end

      should "INSERT a value into the haystack and identify the search result" do
        assert_equal <<~SQL.squish, insert.to_sql.strip
          INSERT INTO haystack (search_result_type, search_result_id, text, search_vector)
          SELECT * FROM (SELECT
            'Book'::varchar "search_result_type",
            books.id::integer "search_result_id",
            books.title::text "text",
            setweight(to_tsvector('hayfork', replace(books.title::varchar, '-', ' ')), 'C') "search_vector"
          FROM (SELECT NEW.*) "books") "x"
          WHERE "x"."text" != '';
        SQL
      end
    end

    should "incorporate relation's joins and conditions" do
      @relation = Book.joins(:author).merge(Author.where(name: "Potok".."Tolkien"))
      @bindings = [ Binding(Hayfork::SEARCH_RESULT_TYPE, "Book"), ]
      assert_equal <<~SQL.squish, insert.to_sql.strip
        INSERT INTO haystack (search_result_type)
        SELECT * FROM
          (SELECT 'Book'::varchar "search_result_type" FROM (SELECT NEW.*) "books"
          INNER JOIN "authors" ON "authors"."id" = "books"."author_id"
          WHERE "authors"."name" BETWEEN 'Potok' AND 'Tolkien') "x"
        WHERE "x"."text" != '';
      SQL
    end

  end


private
  attr_reader :relation, :bindings

  def statement
    @statement ||= Hayfork::Statement.new(Haystack, Book.all, :title)
  end

  def Binding(column_name, raw_value)
    column = Haystack.columns_hash.fetch(column_name)
    Hayfork::Binding.new(statement, column, raw_value)
  end

  def insert
    Hayfork::InsertSql.new(Haystack, relation, bindings)
  end

end
