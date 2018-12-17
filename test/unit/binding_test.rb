require "test_helper"

class BindingTest < Minitest::Test


  context "#quoted_value" do
    should "cast values when types don't match" do
      assert_equal "books.title::integer", Binding("search_result_id", books[:title]).quoted_value
    end

    should "not cast values when types do match" do
      assert_equal "books.author_id", Binding("search_result_id", books[:author_id]).quoted_value
    end

    should "cast values to tsvector with a special function" do
      assert_equal <<~SQL.strip, Binding("search_vector", books[:title]).quoted_value
        setweight(to_tsvector('hayfork', replace(books.title::varchar, '-', ' ')), 'C')
      SQL
    end

    should "use the :dictionary option when casting values to tsvector" do
      statement.dictionary = "CUSTOM_DICTIONARY"
      assert_equal <<~SQL.strip, Binding("search_vector", books[:title]).quoted_value
        setweight(to_tsvector('CUSTOM_DICTIONARY', replace(books.title::varchar, '-', ' ')), 'C')
      SQL
    end

    should "use the :weight option when casting values to tsvector" do
      statement.weight = "A"
      assert_equal <<~SQL.strip, Binding("search_vector", books[:title]).quoted_value
        setweight(to_tsvector('hayfork', replace(books.title::varchar, '-', ' ')), 'A')
      SQL
    end

    should "apply unnested" do
      statement.unnest
      assert_equal "unnest(string_to_array(books.title::text, E'\\n'))", Binding("text", books[:title]).quoted_value
    end
  end


  should "raise an exception if an attribute doesn't exist" do
    assert_raises Hayfork::ColumnNotFoundError do
      Binding("text", books[:nope]).quoted_value
    end
  end


private

  def books
    Book.arel_table
  end

  def statement
    @statement ||= Hayfork::Statement.new(Haystack, Book.all, :title)
  end

  def Binding(column_name, raw_value)
    column = Haystack.columns_hash.fetch(column_name)
    Hayfork::Binding.new(statement, column, raw_value)
  end

end
