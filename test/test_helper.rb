$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "hayfork"

require "minitest/reporters/turn_reporter"
MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new

require "database_cleaner"
require "shoulda/context"
require "rr"
require "minitest/autorun"
require "pry"

require "active_record"
require "support/models/author"
require "support/models/book"
require "support/models/haystack"

connection_url = "'postgresql://#{ENV["POSTGRES_USER"]}:#{ENV["POSTGRES_PASSWORD"]}@localhost:5432'" if ENV["POSTGRES_PASSWORD"]
system "psql #{connection_url} -c 'create database hayfork_test'"

ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  host: "localhost",
  database: "hayfork_test",
  username: ENV["POSTGRES_USER"],
  password: ENV["POSTGRES_PASSWORD"],
  verbosity: "quiet")

load File.join(File.dirname(__FILE__), "support", "db", "schema.rb")

ActiveRecord::Base.connection.execute <<~SQL
  CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
  DROP TEXT SEARCH CONFIGURATION IF EXISTS public.hayfork;
  CREATE TEXT SEARCH CONFIGURATION public.hayfork ( COPY = pg_catalog.english );
  ALTER TEXT SEARCH CONFIGURATION public.hayfork ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, hword, hword_part, word WITH unaccent, english_stem;
SQL

DatabaseCleaner.strategy = :transaction
