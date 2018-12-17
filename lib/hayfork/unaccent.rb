module Hayfork
  module Unaccent

    def unaccent(string)
      string.each_char.map { |char| RULES.fetch(char, char) }.join
    end

    # Use Postgres's own rules so this method's behavior matches Postgres's `unaccent` function.
    RULES = Hash[File.read(File.expand_path("../../../postgres/unaccent.rules", __FILE__)).scan(/^([^\t]+)\t(.*)$/)].freeze

  end
end
