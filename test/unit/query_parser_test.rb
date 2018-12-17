require "test_helper"
require "generators/hayfork/templates/query"

class QueryParserTest < Minitest::Test

  should "treat a single word as a single token" do
    assert_parses "hello", to: [
      Phrase(%w{ hello }) ]
  end

  should "split words into tokens on whitespace" do
    assert_parses "hello world", to: [
      Phrase(%w{ hello }),
      Phrase(%w{ world }) ]
  end

  should "split words into tokens on punctuation" do
    assert_parses "hello,world", to: [
      Phrase(%w{ hello }),
      Phrase(%w{ world }) ]
  end

  should "unaccent characters" do
    assert_parses "schön", to: [
      Phrase(%w{ schon }) ]
  end

  should "break apart hyphenated words" do
    assert_parses "long-expected", to: [
      Phrase(%w{ long }),
      Phrase(%w{ expected }) ]
  end

  should "identify exact phrases" do
    assert_parses 'A "Mighty Fortress"', to: [
      Phrase(%w{ A }),
      Phrase(%w{ Mighty Fortress }) ]
  end

private

  def assert_parses(input, to: [])
    query = Query.parse(input)
    assert_equal to, query.phrases
  end

  def Phrase(words)
    Query::ExactPhrase.new(words)
  end

end
