require "rails"
require "rails/generators"
require "rails/generators/active_record"

module Hayfork
  module Generators
    class HaystackGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)

      # `argument :name` is defined in ::NamedBase,
      # but we override it to provide a default value.
      argument :name, type: :string, default: "haystack"

      def copy_model
        template "model.rb", "app/models/#{file_name}.rb"
      end

      def copy_migration
        migration_template "migrations/create.rb", "#{db_migrate_path}/create_#{table_name}.rb", migration_version: migration_version
      end

      def copy_triggers
        template "triggers.rb", "lib/#{file_name}_triggers.rb"
      end

      def copy_query_models
        template "query.rb", "app/models/query.rb"
        template "query/exact_phrase.rb", "app/models/query/exact_phrase.rb"
        template "query/object.rb", "app/models/query/object.rb"
        template "query/parser.rb", "app/models/query/parser.rb"
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
