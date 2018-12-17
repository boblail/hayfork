require "test_helper"

class SearchTest < Minitest::Test

  def setup
    DatabaseCleaner.start

    triggers do
      foreach Book do |index|
        index.insert(:title)
        index.insert(author: :name)
      end
    end
  end

  def teardown
    DatabaseCleaner.clean
  end


  context "Haystack.serach" do
    should "find words that share the same stem in English" do
      book = Book.create! title: "The Historian"
      assert_finds book, 'Historians'
    end

    should "match words regardless of case and punctuation" do
      book = Book.create! title: "Jonathan Strange & Mr. Norrell"
      assert_finds book, 'jonathan strange'
      assert_finds book, 'Mr Norrell'
    end

    should "match phrases exactly when quoted" do
      book1 = Book.create! title: "the quick brown fox"
      book2 = Book.create! title: "the brown fox is quick"
      assert_finds book1, '"quick brown fox"'
      refute_finds book2, '"quick brown fox"'
    end

    should "match hyphenated words in exact phrases" do
      book = Book.create! title: "Come, Thou Long-Expected Jesus"
      assert_finds book, '"Come, Thou Long-Expected Jesus"'
    end

    should "match words regardless of accented characters" do
      book = Book.create! title: "Wie schön leuchtet"
      assert_finds book, 'schön'
      assert_finds book, 'schon'
    end

    context "given two query words" do
      should "find results even if the words are found in separate fields" do
        book = Book.create!(title: "The Chosen", author: Author.create!(name: "Chaim Potok"))

        assert_finds book, 'Potok Chosen'
      end

      should "return only a single result for a record that's matched by more than one field" do
        book = Book.create!(title: "The Chosen", author: Author.create!(name: "Chaim Potok"))

        assert_equal 1, search('Potok Chosen').length
      end

      should "not return results that don't contain all the query words" do
        Book.create!(title: "The Chosen", author: Author.create!(name: "Chaim Potok"))
        Book.create!(title: "Perelandra", author: Author.create!(name: "C. S. Lewis"))

        assert_equal 0, search('Lewis Chosen').length
      end
    end

  end

private

  def triggers(&block)
    triggers = Hayfork.maintain(Haystack, &block)
    Haystack.connection.execute triggers.replace
  end

  def search(query)
    Haystack.search(query)
  end

  def assert_finds(expected_result, query, message=nil)
    assert_includes search(query), expected_result, message
  end

  def refute_finds(unexpected_result, query, message=nil)
    refute_includes search(query), unexpected_result, message
  end

end
