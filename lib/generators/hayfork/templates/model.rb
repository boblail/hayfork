class <%= class_name %> < ActiveRecord::Base
<% unless table_name == class_name.tableize -%>
  self.table_name = "<%= table_name %>"
<% end -%>

  belongs_to :search_result, polymorphic: true

  def self.search(querystring)
    ::Query.parse(querystring).against(all)
      .select(:search_result_type, :search_result_id).distinct
      .preload(:search_result).map(&:search_result)
  end

end
