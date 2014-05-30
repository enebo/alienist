require 'alienist/model/java_primitive'

module Alienist
  class JavaByte < Alienist::JavaPrimitive
    def self.parse(reader)
      new reader.read_byte
    end
  end
end
