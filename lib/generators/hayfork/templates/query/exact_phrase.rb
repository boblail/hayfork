module Query
  class ExactPhrase < Struct.new(:words)

    def apply(set)
      set.where(Arel::Nodes::InfixOperation.new("@@",
        set.arel_table[Hayfork::SEARCH_VECTOR],
        to_tsquery(Hayfork.default_dictionary, words.join(" <-> "))))
    end

  private

    def to_tsquery(dictionary, querystring)
      Arel::Nodes::NamedFunction.new("to_tsquery", [
        Arel::Nodes.build_quoted(dictionary),
        Arel::Nodes.build_quoted(querystring) ])
    end

  end
end
