require "rails"
require "rails/generators"
require "rails/generators/active_record"

module Hayfork
  module Generators
    class CreateOrReplaceMigration < Rails::Generators::Actions::CreateMigration
      def initialize(base, destination, data, config = {})
        config[:force] = true
        super
      end

      def identical?
        false
      end
    end

    module CreateOrReplaceMigrationConcern
      def create_migration(destination, data, config = {}, &block)
        action CreateOrReplaceMigration.new(self, destination, block || data.to_s, config)
      end
    end

    class RebuildGenerator < ActiveRecord::Generators::Base
      include CreateOrReplaceMigrationConcern

      source_root File.expand_path("templates", __dir__)

      # `argument :name` is defined in ::NamedBase,
      # but we override it to provide a default value.
      argument :name, type: :string, default: "haystack"

      def copy_migration
        migration_template "migrations/rebuild.rb", "#{db_migrate_path}/rebuild_#{table_name}.rb", migration_version: migration_version
      end

      def table_name
        return "haystack" if class_name == "Haystack"
        super
      end

      def migration_version
        return unless Rails::VERSION::MAJOR >= 5
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end

    end
  end
end
