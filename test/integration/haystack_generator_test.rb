require "test_helper"
require "generators/hayfork/haystack_generator"

class HaystackGeneratorTest < Rails::Generators::TestCase
  tests Hayfork::Generators::HaystackGenerator
  destination File.expand_path("../../../tmp", __FILE__)

  setup do
    prepare_destination
  end

  context "without a model name" do
    setup do
      run_generator
    end

    should "generate a model named Haystack" do
      assert_file "app/models/haystack.rb" do |file|
        assert_match /^class Haystack </, file
        assert_match /self\.table_name = "haystack"/, file
      end
    end

    should "generate a migration to create a table named `haystack`" do
      assert_migration "db/migrate/create_haystack.rb"
    end

    should "generate a file for triggers" do
      assert_file "lib/haystack_triggers.rb"
    end

    should "generate query files" do
      assert_file "app/models/query.rb"
      assert_file "app/models/query/exact_phrase.rb"
      assert_file "app/models/query/object.rb"
      assert_file "app/models/query/parser.rb"
    end
  end

  context "given a model name" do
    setup do
      run_generator %w{monster}
    end

    should "generate a model" do
      assert_file "app/models/monster.rb" do |file|
        assert_match /^class Monster </, file
        refute_match /self\.table_name =/, file
      end
    end

    should "generate a migration to create the appropriate table" do
      assert_migration "db/migrate/create_monsters.rb"
    end

    should "generate a file for triggers" do
      assert_file "lib/monster_triggers.rb"
    end
  end

end
