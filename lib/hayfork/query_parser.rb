module Hayfork
  class QueryParser
    attr_reader :klass, :querystring

    def initialize(klass, querystring)
      @klass = klass
      @querystring = querystring
    end

    def parse!
      phrases = []
      scanner = StringScanner.new(Hayfork.unaccent(querystring))

      until scanner.eos?
        parse_phrase(scanner.scan(/[^"]+/), phrases)
        break if scanner.eos?

        scanner.getch # "
        parse_exact_phrase(scanner.scan(/[^"]+/), phrases)
        scanner.getch # "
      end

      klass.new(phrases)
    end

    def parse_phrase(querystring, phrases)
      raise NotImplementedError
    end

    def parse_exact_phrase(querystring, phrases)
      raise NotImplementedError
    end

  end
end
