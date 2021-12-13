require "hayfork/binding"
require "hayfork/insert_sql"
require "hayfork/update_sql"
require "hayfork/delete_sql"

module Hayfork
  class Statement
    attr_reader :haystack, :relation, :value
    attr_accessor :weight, :dictionary

    def initialize(haystack, relation, field, options={})
      @haystack = haystack
      @relation = relation.all
      @weight = options.fetch(:weight, Hayfork.default_weight) # TODO: validate weight
      @dictionary = options.fetch(:dictionary, Hayfork.default_dictionary)
      @attributes = {}.with_indifferent_access
      @unnest = false
      @unsearchable = false

      case field
      when Arel::Predications
        @value = field
      when String
        @value = model.arel_table[field]
      when Symbol
        @value = model.arel_table[field.to_s]
      when Hash
        reflection = reflection_for(field.keys.first)
        joins field.keys.first
        @value = reflection.klass.arel_table[field.values.first.to_s]
      else
        fail ArgumentError, "Unrecognized value for `field`: #{field.inspect}"
      end
    end



    def joins(join_value)
      @relation = Hayfork.join(relation, join_value)
      self
    end

    def where(where_value)
      @relation = relation.where(where_value)
      self
    end

    def merge(attrs = {})
      attributes.merge! attrs.stringify_keys.except(
        Hayfork::SEARCH_VECTOR,
        Hayfork::TEXT,
        Hayfork::SOURCE_TYPE,
        Hayfork::SOURCE_ID)
      self
    end

    def unsearchable
      @unsearchable = true
      self
    end

    def unnest
      @unnest = true
      self
    end



    def unsearchable?
      @unsearchable == true
    end

    def unnest?
      @unnest == true
    end

    def may_change_on_update?
      !update.values_to_check_on_update.empty?
    end



    def insert
      InsertSql.new(haystack, relation, bindings)
    end

    def update
      UpdateSql.new(haystack, relation, bindings)
    end

    def delete
      DeleteSql.new(haystack, relation, bindings)
    end



    def bindings
      @bindings ||= (haystack.columns.each_with_object([]) do |column, bindings|
        next if column.name == Hayfork::SEARCH_VECTOR && unsearchable?

        value = attributes.fetch column.name do
          case column.name
          when Hayfork::SEARCH_RESULT_TYPE then model.name
          when Hayfork::SEARCH_RESULT_ID then model.arel_table["id"]
          when Hayfork::SEARCH_VECTOR, Hayfork::TEXT then self.value
          when Hayfork::SOURCE_TYPE then self.value.relation.send(:type_caster).send(types_method).name
          when Hayfork::SOURCE_ID then self.value.relation["id"]
          when Hayfork::FIELD then self.value.name
          end
        end

        next unless value
        value = model.arel_table[value] if value.is_a? Symbol
        bindings.push Hayfork::Binding.new(self, column, value)
      end)
    end



  private
    attr_reader :attributes

    def model
      relation.model
    end

    def reflection_for(association)
      Hayfork.reflection_for(model, association)
    end

    def types_method
      before_rails61? ? :types : :klass
    end

    def before_rails61?
      return true if ActiveRecord::VERSION::MAJOR < 6

      ActiveRecord::VERSION::MINOR < 1
    end

  end
end
