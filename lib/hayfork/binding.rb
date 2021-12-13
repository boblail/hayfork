module Hayfork
  class Binding < Struct.new(:statement, :column, :raw_value)

    def to_sql
      "#{quoted_value} \"#{column.name}\""
    end
    alias to_s to_sql

    def column_name
      column.name
    end
    alias key column_name

    def quoted_value
      case raw_value
      when Arel::Attributes::Attribute
        value_column = raw_value.relation.send(:type_caster).send(types_method).columns_hash[raw_value.name.to_s]
        fail Hayfork::ColumnNotFoundError, "'#{raw_value.name}' is not a column on '#{raw_value.relation.name}'" unless value_column

        value = "#{raw_value.relation.name}.#{raw_value.name}"

        unless column.sql_type == value_column.sql_type
          type = SPECIAL_CASTS.fetch(column.sql_type, column.sql_type)
          value = "#{value}::#{type}"
        end

        if statement.unnest? && [Hayfork::SEARCH_VECTOR, Hayfork::TEXT].member?(column.name)
          value = "unnest(string_to_array(#{value}, E'\\n'))"
        end

        if column.type == :tsvector

          # Postgres does not handle hyphens well.
          #
          # Notice how, in the following example, the way it breaks up
          # those words throws off the index (Jesus is the fifth word
          # not the third or fourth). This prevents you from constructing
          # an exact-phrase query for a hyphenated word:
          #
          #   > select to_tsvector('hayfork', 'thou long-expected jesus');
          #   { 'expect':4 'jesus':5 'long':3 'long-expect':2 'thou':1 }
          #
          #
          # We'll coerce Postgres into treating hyphenated words as two words.

          value = "setweight(to_tsvector('#{statement.dictionary}', replace(#{value}, '-', ' ')), '#{statement.weight}')"
        end

        value

      when Arel::Nodes::Node
        raw_value.to_sql

      else
        type = SPECIAL_CASTS.fetch(column.sql_type, column.sql_type)
        "#{statement.haystack.connection.quote(raw_value)}::#{type}"

      end
    end

  private

    def types_method
      before_rails61? ? :types : :klass
    end

    def before_rails61?
      return true if ActiveRecord::VERSION::MAJOR < 6

      ActiveRecord::VERSION::MINOR < 1
    end

    SPECIAL_CASTS = {
      "character varying" => "varchar",
      "tsvector" => "varchar"
    }.freeze

  end
end
