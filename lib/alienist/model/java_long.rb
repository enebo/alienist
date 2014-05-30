require 'alienist/model/java_primitive'

module Alienist
  class JavaLong < Alienist::JavaPrimitive
    def self.parse(reader)
      new reader.read_long
    end
  end
end
