require "hayfork/errors"
require "hayfork/join"
require "hayfork/query_object"
require "hayfork/query_parser"
require "hayfork/trigger_builder"
require "hayfork/triggers"
require "hayfork/unaccent"
require "hayfork/version"

module Hayfork
  extend Hayfork::Unaccent, Hayfork::Join

  TEXT = "text".freeze
  SEARCH_VECTOR = "search_vector".freeze
  SEARCH_RESULT_TYPE = "search_result_type".freeze
  SEARCH_RESULT_ID = "search_result_id".freeze
  SOURCE_TYPE = "source_type".freeze
  SOURCE_ID = "source_id".freeze
  FIELD = "field".freeze

  @default_weight = "C".freeze
  @default_dictionary = "hayfork".freeze

  class << self
    attr_accessor :default_weight, :default_dictionary

    def maintain(haystack, &block)
      triggers = Triggers.new(haystack)
      TriggerBuilder.new(triggers).instance_eval(&block)
      haystack.singleton_class.send(:attr_reader, :triggers)
      haystack.instance_variable_set :@triggers, triggers
    end
  end

end
