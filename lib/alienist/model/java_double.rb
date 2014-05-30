require 'alienist/model/java_primitive'

module Alienist
  class JavaDouble < Alienist::JavaPrimitive
    def self.parse(reader)
      new reader.read_double
    end
  end
end
