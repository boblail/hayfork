require "triggers"

class Rebuild<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def up
    execute <%= class_name %>.triggers.replace
    execute <%= class_name %>.triggers.rebuild.lines
  end
end
