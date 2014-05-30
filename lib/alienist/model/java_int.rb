require 'alienist/model/java_primitive'

module Alienist
  class JavaInt < Alienist::JavaPrimitive
    def self.parse(reader)
      new reader.read_int
    end
  end
end
