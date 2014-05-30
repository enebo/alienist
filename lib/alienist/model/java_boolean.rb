require 'alienist/model/java_primitive'

module Alienist
  class JavaBoolean < Alienist::JavaPrimitive
    def self.parse(reader)
      new reader.read_boolean
    end
  end
end
