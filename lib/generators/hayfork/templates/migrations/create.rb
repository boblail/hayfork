class Create<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    enable_extension :unaccent

    # Full-Text Search in Postgres can be configured extensively.
    #
    # Custom Parsers are able to match entities in documents and handle them
    # differently. Custom Dictionaries can be used to tune search for different
    # languages and to ignore certain words.
    #
    # Learn more at https://www.postgresql.org/docs/10/textsearch.html
    #
    # This block creates a TEXT SEARCH CONFIGURATION specifically for use
    # by Hayfork that uses an English dictionary and normalizes characters
    # by stripping accent marks and converting special characters (like smart
    # quotes) to their easily-typed ASCII counterparts (like straight quotes).
    #
    execute <<~SQL
      CREATE TEXT SEARCH CONFIGURATION public.hayfork ( COPY = pg_catalog.english );
      ALTER TEXT SEARCH CONFIGURATION public.hayfork ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, hword, hword_part, word WITH unaccent, english_stem;
    SQL

    create_table :<%= table_name %>, id: false do |t|
      t.string :<%= Hayfork::SEARCH_RESULT_TYPE %>, null: false
      t.integer :<%= Hayfork::SEARCH_RESULT_ID %>, null: false
      t.tsvector :<%= Hayfork::SEARCH_VECTOR %>
      t.text :<%= Hayfork::TEXT %>

      # Add additional columns to <%= table_name %> here.
      #
      # For example, to allow users to search only documents of their
      # own creation:
      #
      #    t.belongs_to :user, null: false
      #
      # or to allow users to constrain a search by a particular field:
      #
      #    t.string :field, null: false
      #
      # or to allow finding a result by the of content of its subrecords:
      #
      #    t.integer :ref_id
      #

      # If you add columns that will always be used in searches (like `user_id`),
      # consider including them in this index. For example:
      #
      #    enable_extension :btree_gist
      #    t.index [:tenant_id, :<%= Hayfork::SEARCH_VECTOR %>], using: "gist"
      #
      t.index :<%= Hayfork::SEARCH_VECTOR %>, using: "gist"
    end
  end
end
