require "test_helper"

class UnaccentTest < Minitest::Test

  context "Hayfork.unaccent" do
    should "strip accent marks" do
      examples = {
        "jalapeño" => "jalapeno",
        "blessèd" => "blessed" }

      examples.each do |input, output|
        assert_equal output, Hayfork.unaccent(input)
      end
    end

    should "expand ligatures" do
      examples = {
        "waﬄe" => "waffle",
        "firﬆ" => "first" }

      examples.each do |input, output|
        assert_equal output, Hayfork.unaccent(input)
      end
    end

    should "simplify punctuation" do
      examples = {
        "—" => "-",
        "…" => "...",
        "‛" => "'" }

      examples.each do |input, output|
        assert_equal output, Hayfork.unaccent(input)
      end
    end
  end

end
