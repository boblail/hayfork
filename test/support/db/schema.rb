ActiveRecord::Schema.define(version: 1) do

  create_table "haystack", force: true do |t|
    t.string   "search_result_type", null: false
    t.integer  "search_result_id", null: false
    t.string   "source_type", null: false
    t.integer  "source_id", null: false
    t.string   "field", null: false
    t.text     "text", null: false
    t.tsvector "search_vector"
    t.string   "another_field"
  end

  create_table "books", force: true do |t|
    t.integer  "author_id", null: true
    t.string   "title", null: false
    t.string   "isbn", null: true
    t.text     "description", null: true
  end

  create_table "authors", force: true do |t|
    t.string   "name", null: false
  end

end
