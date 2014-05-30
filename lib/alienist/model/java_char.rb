require 'alienist/model/java_primitive'

module Alienist
  class JavaChar < Alienist::JavaPrimitive
    def self.parse(reader)
      new reader.read_char
    end
  end
end
