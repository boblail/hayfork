require_relative "query/parser"
require_relative "query/object"

module Query

  def self.parse(querystring)
    Query::Parser.new(Query::Object, querystring).parse!
  end

end
