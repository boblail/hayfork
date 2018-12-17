module Hayfork
  class InsertSql
    attr_reader :haystack, :relation, :bindings

    def initialize(haystack, relation, bindings)
      @haystack = haystack
      @relation = relation
      @bindings = bindings
    end

    def to_sql(from: true)
      select_statement = relation.select(bindings.map(&:to_s))
      select_statement = select_statement.from("(SELECT NEW.*) \"#{relation.table_name}\"") if from

      <<~SQL
        INSERT INTO #{haystack.table_name} (#{bindings.map(&:key).join(", ")}) SELECT * FROM (#{select_statement.to_sql}) "x" WHERE "x"."#{Hayfork::TEXT}" != '';
      SQL
    end
    alias to_s to_sql

  end
end
