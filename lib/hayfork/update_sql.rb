require "hayfork/delete_sql"
require "hayfork/insert_sql"

module Hayfork
  class UpdateSql
    attr_reader :haystack, :relation, :bindings

    def initialize(haystack, relation, bindings)
      @haystack = haystack
      @relation = relation
      @bindings = bindings
    end

    def to_sql
      sql = values_to_check_on_update.map { |field| "OLD.#{field} IS DISTINCT FROM NEW.#{field}" }.join(" OR ")

      <<-SQL
    IF #{sql} THEN
      #{delete.to_sql.strip}
      #{insert.to_sql.strip}
    END IF;
      SQL
    end
    alias to_s to_sql

    def model
      relation.model
    end

    def values_to_check_on_update
      foreign_keys_by_table_name = {}
      (relation.joins_values + relation.left_outer_joins_values).each do |join_value|
        if join_value.is_a? String
          fail NotImplementedError, "Unhandled literal join: #{join_value.inspect}"
        end

        reflection = reflection_for(join_value)
        table_name = reflection.table_name
        reflection = reflection.through_reflection if reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)

        case reflection
        when ActiveRecord::Reflection::BelongsToReflection
          foreign_keys_by_table_name[table_name] = [ reflection.foreign_key.to_s ]
        when ActiveRecord::Reflection::HasManyReflection
          foreign_keys_by_table_name[table_name] = [] # assume identity keys won't change
        when ActiveRecord::Reflection::HasAndBelongsToManyReflection
          foreign_keys_by_table_name[reflection.join_table] = [] # assume identity keys won't change
          foreign_keys_by_table_name[table_name] = [] # assume identity keys won't change
        else
          fail NotImplementedError, "Unhandled reflection: #{reflection.class} (join_value: #{join_value.inspect})"
        end
      end


      values_being_written = bindings.pluck(:raw_value) + predicate_fields
      values_to_check_on_update = Set.new

      values_being_written.each do |value|
        next if value.is_a?(String) # constant
        if value.relation.name == relation.table_name
          values_to_check_on_update << value.name.to_s
        else
          # The value isn't a field of the current record but of a joined record.
          # That record hasn't changed so we don't care about its value; but we
          # do care whether this record's foreign keys have changed (which would
          # cause it to be associated with a different joined record).
          values_to_check_on_update.merge foreign_keys_by_table_name.fetch(value.relation.name)
        end
      end

      values_to_check_on_update - model.readonly_attributes
    end

  private

    def insert
      InsertSql.new(haystack, relation, bindings)
    end

    def delete
      DeleteSql.new(haystack, relation, bindings)
    end

    def predicate_fields
      relation.where_clause.send(:predicates).map(&method(:field_from_predicate))
    end

    def field_from_predicate(predicate)
      case predicate
      when Arel::Nodes::Between,
           Arel::Nodes::Equality,
           Arel::Nodes::GreaterThan,
           Arel::Nodes::GreaterThanOrEqual,
           Arel::Nodes::In,
           Arel::Nodes::LessThan,
           Arel::Nodes::LessThanOrEqual,
           Arel::Nodes::NotEqual,
           Arel::Nodes::NotIn
        field_from_predicate(predicate.left)
      when Arel::Attributes::Attribute
        predicate
      else
        fail NotImplementedError, "Unhandled predicate: #{predicate.class}: #{predicate.inspect}"
      end
    end

    def reflection_for(association)
      Hayfork.reflection_for(model, association)
    end

  end
end
