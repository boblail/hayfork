module Hayfork
  class DeleteSql
    attr_reader :haystack, :relation, :bindings

    def initialize(haystack, relation, bindings)
      @haystack = haystack
      @relation = relation
      @bindings = bindings.reject { |binding| binding.key == Hayfork::SEARCH_VECTOR || binding.key == Hayfork::TEXT }
    end

    def to_sql
      select_statement = relation.select(bindings.map(&:to_s))
      select_statement = select_statement.from("(SELECT OLD.*) \"#{relation.table_name}\"")

      constraints = bindings.map { |binding| "#{haystack.table_name}.#{binding.key}=x.#{binding.key}" }.join(" AND ")

      <<~SQL
        DELETE FROM #{haystack.table_name} USING (#{select_statement.to_sql}) "x" WHERE #{constraints};
      SQL
    end
    alias to_s to_sql

  end
end
