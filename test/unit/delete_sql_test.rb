require "test_helper"

class DeleteSqlTest < Minitest::Test
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

      should "DELETE the entry from the haystack, treating everything except TEXT and SEARCH_VECTOR as identifying information" do
        assert_equal <<~SQL.squish, delete.to_sql.strip
          DELETE FROM haystack
          USING (SELECT
            'Book'::varchar "search_result_type",
            books.id::integer "search_result_id"
          FROM (SELECT OLD.*) "books") "x"
          WHERE haystack.search_result_type=x.search_result_type
          AND haystack.search_result_id=x.search_result_id;
        SQL
      end
    end

    should "incorporate relation's joins and conditions" do
      @relation = Book.joins(:author).merge(Author.where(name: "Potok".."Tolkien"))
      @bindings = [ Binding(Hayfork::SEARCH_RESULT_TYPE, "Book"), ]
      assert_equal <<~SQL.squish, delete.to_sql.strip
        DELETE FROM haystack
        USING
          (SELECT 'Book'::varchar "search_result_type"
          FROM (SELECT OLD.*) "books"
          INNER JOIN "authors" ON "authors"."id" = "books"."author_id"
          WHERE "authors"."name" BETWEEN 'Potok' AND 'Tolkien') "x"
        WHERE haystack.search_result_type=x.search_result_type;
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

  def delete
    Hayfork::DeleteSql.new(Haystack, relation, bindings)
  end

end
