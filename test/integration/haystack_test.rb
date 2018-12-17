require "test_helper"

class HaystackTest < Minitest::Test

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end


  context "If we're maintaining just books' titles in the haystack" do
    setup do
      triggers do
        foreach Book do |index|
          index.insert(:title)
        end
      end
    end

    context "Inserting a new book" do
      should "create an entry in the haystack" do
        book = Book.create!(title: "The Chosen")

        assert_equal [[book.id, "The Chosen"]], Haystack.pluck(:search_result_id, :text)
      end
    end

    context "Deleting a book" do
      should "remove [only] its entry from the haystack" do
        book1 = Book.create!(title: "The Chosen")
        book2 = Book.create!(title: "Perelandra")
        book1.delete

        assert_equal [[book2.id, "Perelandra"]], Haystack.pluck(:search_result_id, :text)
      end
    end

    context "Renaming a book" do
      should "replace [only] its entry in the haystack" do
        book1 = Book.create!(title: "The Chosen")
        book2 = Book.create!(title: "My Name is Asher Lev")
        book2.update_column :title, "The Gift of Asher Lev"

        assert_equal [
          [book1.id, "The Chosen"],
          [book2.id, "The Gift of Asher Lev"],
        ], Haystack.pluck(:search_result_id, :text)
      end
    end

    context "Changing a book's ISBN" do
      should "do nothing to the haystack" do
        book = Book.create!(title: "The Chosen", isbn: "0449213447")

        before = Haystack.pluck(:id)
        book.update_column :isbn, "9780449213445"
        assert_equal before, Haystack.pluck(:id)
      end
    end
  end

private

  def triggers(&block)
    triggers = Hayfork.maintain(Haystack, &block)
    Haystack.connection.execute triggers.replace
  end

end
