require "test_helper"
require "generators/hayfork/rebuild_generator"

class RebuildGeneratorTest < Rails::Generators::TestCase
  tests Hayfork::Generators::RebuildGenerator
  destination File.expand_path("../../../tmp", __FILE__)

  setup do
    prepare_destination
  end

  context "without a model name" do
    setup do
      run_generator
    end

    should "generate a migration to rebuild the Haystack" do
      assert_migration "db/migrate/rebuild_haystack.rb" do |file|
        assert_match /^require \"haystack_triggers\"/, file
        assert_match /^class RebuildHaystack < ActiveRecord::Migration/, file
        assert_match /execute Haystack.triggers/, file
      end
    end
  end

  context "when run a second time" do
    setup do
      stub(ActiveRecord::Migration).next_migration_number(anything).returns(1)
      run_generator
    end

    should "replace any other migrations named 'rebuild_haystack.rb'" do
      assert_file "db/migrate/1_rebuild_haystack.rb"

      stub(ActiveRecord::Migration).next_migration_number(anything).returns(2)
      run_generator

      assert_file "db/migrate/2_rebuild_haystack.rb"
      assert_no_file "db/migrate/1_rebuild_haystack.rb"
    end
  end

  context "given a model name" do
    setup do
      run_generator %w{monster}
    end

    should "generate a migration to rebuild the Haystack" do
      assert_migration "db/migrate/rebuild_monsters.rb" do |file|
        assert_match /^require \"monster_triggers\"/, file
        assert_match /^class RebuildMonsters < ActiveRecord::Migration/, file
        assert_match /execute Monster.triggers/, file
      end
    end
  end

end
