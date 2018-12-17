require_relative "exact_phrase"

module Query
  class Parser < Hayfork::QueryParser

    def parse_phrase(querystring, phrases)
      tokenize_words(querystring).each do |word|
        phrases << Query::ExactPhrase.new([ word ])
      end
    end

    def parse_exact_phrase(querystring, phrases)
      phrases << Query::ExactPhrase.new(tokenize_words(querystring))
    end

    def tokenize_words(querystring)
      # Postgres does not handle hyphens well.
      #
      # Notice how, in the following example, the way it breaks up
      # the hyphenated word throws off the index (Jesus is the fifth word
      # not the third or fourth). This prevents you from constructing
      # an exact-phrase query for a hyphenated word:
      #
      #   > select to_tsvector('hayfork', 'thou long-expected jesus');
      #   { 'expect':4 'jesus':5 'long':3 'long-expect':2 'thou':1 }
      #
      #
      # We'll coerce Postgres into treating hyphenated words as two words.
      querystring.to_s.scan(/\w+/)
    end

  end
end
