require "test_helper"

class HaystackTest < Minitest::Test

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end


  context "If we're maintaining books in the haystack" do
    setup do
      triggers do
        foreach Book do |index|
          index.insert(:title)
          index.insert(:description)
        end
      end
    end

    context "Inserting a new book" do
      should "create an entry in the haystack" do
        book = Book.create!(title: "The Chosen")

        assert_equal [[book.id, "title", "The Chosen"]], Haystack.pluck(:search_result_id, :field, :text)
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
        book2 = Book.create!(title: "My Name is Asher Lev", description: "Asher Lev is a Ladover Hasid who keeps kosher...")
        book2.update_column :title, "The Gift of Asher Lev"

        assert_equal Set[
          [book1.id, "title", "The Chosen"],
          [book2.id, "description", "Asher Lev is a Ladover Hasid who keeps kosher..."],
          [book2.id, "title", "The Gift of Asher Lev"],
        ], Haystack.pluck(:search_result_id, :field, :text).to_set
      end
    end

    context "Changing a book's ISBN" do
      should "do nothing to the haystack if the ISBN isn't used" do
        book = Book.create!(title: "The Chosen", isbn: "0449213447")

        before = Haystack.pluck(:id)
        book.update_column :isbn, "9780449213445"
        assert_equal before, Haystack.pluck(:id)
      end
    end
  end


  context "If we're maintaining a belongs_to relationship" do
    setup do
      triggers do
        foreach(Book) do
          insert(author: :name)
        end
        foreach(Author) do
          joins :books
          set :search_result_type, "Book"
          set :search_result_id, Book.arel_table[:id]

          insert(:name)
        end
      end
    end

    context "Updating an author" do
      setup do
        @author = Author.create!(name: "Chiam Potok")
        @book1 = Book.create!(title: "The Chosen", author: @author)
        @book2 = Book.create!(title: "My Name is Asher Lev", author: @author)
      end

      should "replace entries for _all_ the author's books" do
        @author.update_column :name, "Chaim Potok"

        assert_equal Set[
          [@book1.id, "name", "Chaim Potok"],
          [@book2.id, "name", "Chaim Potok"],
        ], Haystack.pluck(:search_result_id, :field, :text).to_set
      end

      should "not touch entries for other authors" do
        @book3 = Book.create!(title: "The Graveyard Book", author: Author.create!(name: "Neil Gaiman"))

        before = Haystack.where(search_result_id: @book3.id).pluck(:id)
        @author.update_column :name, "Chaim Potok"
        assert_equal before, Haystack.where(search_result_id: @book3.id).pluck(:id)
      end
    end
  end


  context "If we're maintaining a has_many relationship" do
    setup do
      triggers do
        foreach(Author) do
          insert(:name)
        end
        foreach(Book.joins(:author)) do
          set :search_result_type, "Author"
          set :search_result_id, Author.arel_table[:id]

          insert(:title)
        end
      end
    end

    context "Updating a book's title" do
      setup do
        @author = Author.create!(name: "Chiam Potok")
        @book1 = Book.create!(title: "The Chosen", author: @author)
        @book2 = Book.create!(title: "My Name is Asher Lev", author: @author)
      end

      should "replace [only] the entry for that book" do
        @book2.update_column :title, "The Gift of Asher Lev"

        assert_equal Set[
          [@author.id, "name", "Chiam Potok"],
          [@author.id, "title", "The Chosen"],
          [@author.id, "title", "The Gift of Asher Lev"],
        ], Haystack.pluck(:search_result_id, :field, :text).to_set
      end
    end
  end


private

  def triggers(&block)
    triggers = Hayfork.maintain(Haystack, &block)
    Haystack.connection.execute triggers.replace
  end

end
