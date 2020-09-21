require 'esql/version'
require 'esql/parser'

module Esql
  class Error < StandardError; end

  class InvalidAttributeError < Error
    def initialize(attribute)
      super("No such attribute: #{attribute}")
    end
  end

  class InvalidFunctionError < Error
    def initialize(function)
      super("No such function: #{function}")
    end
  end

  class InvalidRelationshipError < Error
    def initialize(relationship)
      super("No such relationship: #{relationship}")
    end
  end

  class RelationshipTypeError < Error
    def initialize(relationship, actual_type)
      super("#{relationship} is a #{actual_type} relationship")
    end
  end
end
