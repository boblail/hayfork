require "test_helper"
require "generators/hayfork/templates/query"

class QueryObjectTest < Minitest::Test

  context "#against" do
    should "return a null query if no phrases are given" do
      assert_generates where_sql(Haystack.none), from: []
    end

    should "return a simple query for a single phrase" do
      assert_generates <<~SQL.squish.strip, from: [ Phrase(%w{ hello }) ]
        "haystack"."search_vector" @@ to_tsquery('hayfork', 'hello')
      SQL
    end

    should "join multiple words in an exact phrase with <->" do
      assert_generates <<~SQL.squish.strip, from: [ Phrase(%w{ hello world }) ]
        "haystack"."search_vector" @@ to_tsquery('hayfork', 'hello <-> world')
      SQL
    end

    should "select all the hits that match _any_ query phrase but only for the results that match them all" do
      assert_generates <<~SQL.squish.strip, from: [ Phrase(%w{ Martin }), Phrase(%w{ Richard }) ]
        "haystack"."search_result_id" IN ((
          (SELECT "haystack"."search_result_id" FROM "haystack"
            WHERE "haystack"."search_vector" @@ to_tsquery('hayfork', 'Martin'))
          INTERSECT
          (SELECT "haystack"."search_result_id" FROM "haystack"
            WHERE "haystack"."search_vector" @@ to_tsquery('hayfork', 'Richard'))
        ))
        AND ("haystack"."search_vector" @@ to_tsquery('hayfork', 'Martin') OR
             "haystack"."search_vector" @@ to_tsquery('hayfork', 'Richard'))
      SQL
    end
  end

private

  def assert_generates(output, from: [])
    assert_equal output, where_sql(Query::Object.new(from).against(Haystack.all))
  end

  def where_sql(relation)
    relation.where_clause.ast.to_sql
  end

  def Phrase(words)
    Query::ExactPhrase.new(words)
  end

end
