require "test_helper"

class UpdateSqlTest < Minitest::Test
  attr_reader :haystack, :relation, :bindings


  context "#to_sql" do
    context "in the general case" do
      setup do
        @relation = Book.all
        @bindings = [
          Binding(Hayfork::SEARCH_RESULT_TYPE, "Book"),
          Binding(Hayfork::SEARCH_RESULT_ID, Book.arel_table[:id]),
          Binding(Hayfork::TEXT, Book.arel_table[:title]),
          Binding(Hayfork::SEARCH_VECTOR, Book.arel_table[:title]),
          Binding("another_field", Book.arel_table[:isbn]),
        ]
      end

      should "check if relevant values have changed before replacing entries in the Haystack" do
        stub(update).delete.stub!.to_sql.returns("<!-- DELETE -->")
        stub(update).insert.stub!.to_sql.returns("<!-- INSERT -->")
        assert_equal <<~SQL.squish, update.to_sql.squish.strip
          IF OLD.title IS DISTINCT FROM NEW.title OR OLD.isbn IS DISTINCT FROM NEW.isbn THEN
            <!-- DELETE -->
            <!-- INSERT -->
          END IF;
        SQL
      end

      context "when the model uses attr_readonly" do
        setup do
          Book.attr_readonly :isbn
          fail "isbn should be readonly now" unless Book.readonly_attributes.member?("isbn")
        end

        teardown do
          Book.readonly_attributes.delete "isbn"
          fail "isbn should not be readonly now" if Book.readonly_attributes.member?("isbn")
        end

        should "not check values that are readonly" do
          stub(update).delete.stub!.to_sql.returns("<!-- DELETE -->")
          stub(update).insert.stub!.to_sql.returns("<!-- INSERT -->")
          assert_equal <<~SQL.squish, update.to_sql.squish.strip
            IF OLD.title IS DISTINCT FROM NEW.title THEN
              <!-- DELETE -->
              <!-- INSERT -->
            END IF;
          SQL
        end
      end
    end
  end


  context "#values_to_check_on_update" do
    setup do
      @relation = Book.all
      @bindings = [ Binding(Hayfork::SEARCH_VECTOR, Book.arel_table[:title]) ]
    end

    should "always include search_vector_value" do
      assert_equal Set["title"], update.values_to_check_on_update
    end

    should "include merged attributes" do
      bindings.push Binding("another_field", Book.arel_table[:isbn])
      assert_equal Set["title", "isbn"], update.values_to_check_on_update
    end

    should "ignored attributes whose values are constants" do
      bindings.push Binding("another_field", "CONSTANT")
      assert_equal Set["title"], update.values_to_check_on_update
    end


    context "when @relation has JOINs" do
      setup do
        @relation = Book.joins(:author)
        @bindings.push Binding("another_field", Author.arel_table[:name])
      end

      context "on a mutable attribute" do
        should "include the foreign key of a belongs_to association" do
          assert_equal Set["title", "author_id"], update.values_to_check_on_update
        end
      end

      context "on a readonly attribute" do
        setup do
          Book.attr_readonly :author_id
          fail "author_id should be readonly now" unless Book.readonly_attributes.member?("author_id")
        end

        teardown do
          Book.readonly_attributes.delete "author_id"
          fail "author_id should not be readonly now" if Book.readonly_attributes.member?("author_id")
        end

        should "exclude the immutable foreign key" do
          assert_equal Set["title"], update.values_to_check_on_update
        end
      end

      # TODO: do nothing for joins where the foreign_key is on the other table
      # TODO: should handle `belongs_to :through`

    end

    context "when @relation has a WHERE clause" do
      should "include the keys of a vanilla `where`" do
        @relation = Book.where(isbn: "7")
        assert_equal Set["title", "isbn"], update.values_to_check_on_update
      end

      should "include the keys of a `where.not`" do
        @relation = Book.where.not(isbn: "7")
        assert_equal Set["title", "isbn"], update.values_to_check_on_update
      end

      should "include the keys of a `where` that uses Arel" do
        @relation = Book.where(Book.arel_table[:isbn].gteq("7"))
        assert_equal Set["title", "isbn"], update.values_to_check_on_update
      end

      # TODO: should alert of limits — predicates it can't parse, etc

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

  def update
    @update ||= Hayfork::UpdateSql.new(Haystack, relation, bindings)
  end

end
