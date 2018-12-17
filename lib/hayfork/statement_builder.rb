require "hayfork/statement"

module Hayfork
  class StatementBuilder
    attr_reader :row

    def initialize(haystack, relation, attributes: {})
      @haystack = haystack
      @relation = relation
      @attributes = attributes
      @statements = []
      @row = model.arel_table
    end


    def set(key, value)
      @attributes.merge!(key => value)
    end

    def joins(join_value, &block) # reject SQL literals?
      apply? Hayfork.join(relation, join_value), &block
    end

    def where(*args, &block) # reject SQL literals?
      apply? relation.where(*args), &block
    end


    def insert(field, options={})
      Statement.new(haystack, relation, field, options).tap do |statement|
        statement.merge(attributes) if attributes.any?
        statements << statement
      end
    end


    def to_insert_sql(**args)
      statements.map { |statement| "    " << statement.insert.to_sql(**args) }.join.strip
    end

    def to_update_sql
      updates = statements.select(&:may_change_on_update?)
      return "-- nothing to update" if updates.empty?
      updates.map { |statement| "    " << statement.update.to_sql.lstrip }.join.strip
    end

    def to_delete_sql
      statements.map { |statement| "    " << statement.delete.to_sql }.join.strip
    end


    def to_a
      statements
    end

  private
    attr_reader :haystack, :relation, :statements, :attributes

    def apply?(modified_relation, &block)
      if block_given?
        statements = StatementBuilder.new(haystack, modified_relation, attributes: attributes.dup)
        if block.arity.zero?
          statements.instance_eval(&block)
        else
          yield statements
        end
        @statements.concat statements.to_a
      else
        @relation = modified_relation
      end
    end

    def model
      relation.model
    end

  end
end
