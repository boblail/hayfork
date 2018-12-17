require "generators/hayfork/templates/query"

class Haystack < ActiveRecord::Base
  self.table_name = "haystack"

  belongs_to :search_result, polymorphic: true

  def self.search(querystring)
    ::Query.parse(querystring).against(all)
      .select(:search_result_type, :search_result_id).distinct
      .preload(:search_result).map(&:search_result)
  end

end
