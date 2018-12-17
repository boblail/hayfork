require "hayfork/statement_builder"

module Hayfork
  class TriggerBuilder

    def initialize(triggers)
      @triggers = triggers
    end

    def foreach(model, options={}, &block)
      statements = StatementBuilder.new(@triggers.haystack, model.unscope(:order, :select, :group, :having, :offset, :limit))
      statements.instance_eval(&block)
      @triggers << [model, statements, options]
    end

  end
end
