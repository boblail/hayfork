module Hayfork
  module Join

    def join(relation, join_value)
      case join_value
      when String
        relation.joins(join_value)

      when Symbol
        reflection = reflection_for(relation.model, join_value)
        case reflection.macro
        when :has_many, :has_and_belongs_to_many
          relation.left_outer_joins(join_value).where(reflection.klass.arel_table[:id].not_eq(nil))
        when :belongs_to, :has_one
          relation.joins(join_value)
        else
          fail NotImplementedError, "Joins haven't been implemented for #{reflection.macro.inspect} associations"
        end

      else
        fail NotImplementedError, "Statement#joins does not yet accept #{join_value.class} params like #{join_value.inspect}. Will this scenario work with `has_many through:` or `has_one through:`?"
      end
    end

    def reflection_for(model, association)
      reflection = model.reflect_on_association(association)
      fail AssociationNotFoundError, "Association ':#{association}' not found on '#{model}'" unless reflection
      reflection
    end

  end
end
