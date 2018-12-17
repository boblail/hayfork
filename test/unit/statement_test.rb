require "test_helper"

class StatementTest < Minitest::Test
  attr_reader :statement


  context "#bindings" do
    setup do
      @statement = Statement(Book, :title)
    end


    context "by default" do
      should "bind 'search_result_type' to the relation's type" do
        assert_equal "Book", bound_value_of(statement, Hayfork::SEARCH_RESULT_TYPE)
      end

      should "bind 'search_result_id' to the relation's id" do
        assert_equal Book.arel_table["id"], bound_value_of(statement, Hayfork::SEARCH_RESULT_ID)
      end

      should "bind 'search_vector' to the field passed to the statement" do
        assert_equal Book.arel_table["title"], bound_value_of(statement, Hayfork::SEARCH_VECTOR)
      end

      should "bind 'text' to the field passed to the statement" do
        assert_equal Book.arel_table["title"], bound_value_of(statement, Hayfork::TEXT)
      end
    end


    context "given merged attributes" do
      should "allow overriding the binding of 'search_result_type'" do
        assert_equal "Monster", bound_value_of(statement.merge(Hayfork::SEARCH_RESULT_TYPE => "Monster"), Hayfork::SEARCH_RESULT_TYPE)
      end

      should "allow overriding the binding of 'search_result_id'" do
        assert_equal 1, bound_value_of(statement.merge(Hayfork::SEARCH_RESULT_ID => 1), Hayfork::SEARCH_RESULT_ID)
      end

      should "prohibit overriding the binding of 'search_vector'" do
        assert_equal Book.arel_table["title"], bound_value_of(statement.merge(Hayfork::SEARCH_VECTOR => "NOPE"), Hayfork::SEARCH_VECTOR)
      end

      should "prohibit overriding the binding of 'text'" do
        assert_equal Book.arel_table["title"], bound_value_of(statement.merge(Hayfork::TEXT => "NOPE"), Hayfork::TEXT)
      end

      should "include bindings for arbitrary attributes that exist on Haystack" do
        assert_includes statement.merge(another_field: "example").bindings.map(&:key), "another_field"
      end

      should "ignore arbitrary attributes that don't exist on Haystack" do
        refute_includes statement.merge(nope: "example").bindings.map(&:key), "nope"
      end
    end


    should "exclude 'search_vector' when .unsearchable is called" do
      refute_includes statement.unsearchable.bindings.map(&:key), Hayfork::SEARCH_VECTOR
    end
  end


  context "#initialize" do
    should "treat :field as a column of :relation when it is a String" do
      assert_equal Book.arel_table["title"], Statement(Book, "title").value
    end

    should "treat :field as a column of :relation when it is a Symbol" do
      assert_equal Book.arel_table["title"], Statement(Book, :title).value
    end

    should "accept :field as-is when it is an Arel::Predicate" do
      arel = Author.arel_table["name"]
      assert_equal arel, Statement(Book, arel).value
    end

    should "treat :field as a column on an associated table when it is a Hash" do
      assert_equal Author.arel_table["name"], Statement(Book, author: :name).value
    end

    should "join an associated table when :field is a Hash" do
      assert_equal Statement(Book, :title).joins(:author).relation.to_sql,
                   Statement(Book, author: :name).relation.to_sql
    end
  end


  context "#joins" do
    should "use an INNER JOIN for a belongs_to association" do
      assert_equal Book.joins(:author).to_sql,
                   Statement(Book, :title).joins(:author).relation.to_sql
    end

    should "use a LEFT OUTER JOIN for a has_many association" do
      assert_equal Author.left_outer_joins(:books).where(Book.arel_table[:id].not_eq(nil)).to_sql,
                   Statement(Author, :name).joins(:books).relation.to_sql
    end

    # TODO: test :through joins

    should "raise an exception if the association does not exist" do
      assert_raises Hayfork::AssociationNotFoundError do
        Statement(Book, :title).joins(:nothing)
      end
    end
  end


private

  def Statement(relation, field, options={})
    Hayfork::Statement.new(Haystack, relation, field, options)
  end

  def bound_value_of(statement, key)
    hash = statement.bindings.index_by(&:key)
    hash.fetch(key).raw_value
  end

end
