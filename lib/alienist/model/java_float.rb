require 'alienist/model/java_primitive'

module Alienist
  class JavaFloat < Alienist::JavaPrimitive
    def self.parse(reader)
      new reader.read_float
    end
  end
end
