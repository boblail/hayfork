module Hayfork
  class QueryObject
    attr_reader :phrases

    def initialize(phrases)
      @phrases = phrases
    end

    def against(set)
      return set.none if phrases.none?
      return phrases.first.apply(set) if phrases.one?

      # The haystack may contain more than one hit per result.
      #
      # A composite query may match more than one hit for a result.
      # For example, it may match both a hymn's author and its tune.
      #
      # If we search more than one phrase, we want to find all of
      # the hits that match *_any_* of the search phrases but only
      # return hits for results that match *_all_* of the phrases.
      filter_hits_by_any_phrase(filter_results_that_match_all_phrases(set))
    end

  private

    def filter_hits_by_any_phrase(set)
      phrases[1..-1].inject(phrases.first.apply(set)) { |memo, phrase| memo.or(phrase.apply(set)) }
    end

    def filter_results_that_match_all_phrases(set)
      scope = set.select(Hayfork::SEARCH_RESULT_ID)
      set.where(
        set.arel_table[Hayfork::SEARCH_RESULT_ID].in(
          phrases[1..-1].inject(phrases.first.apply(scope).arel) { |memo, phrase| Arel::Nodes::Intersect.new(memo, phrase.apply(scope).arel) }))
    end

  end
end
