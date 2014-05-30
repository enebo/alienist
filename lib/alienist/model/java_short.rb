require 'alienist/model/java_primitive'

module Alienist
  class JavaShort
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def self.parse(reader)
      Alienist::JavaShort.new reader.read_short
    end
  end
end
