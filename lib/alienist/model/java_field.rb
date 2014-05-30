module Alienist
  class JavaField
    attr_reader :id, :name, :type

    def initialize(id, name, type)
      @id, @name, @type = id, name, type
    end
  end
end
