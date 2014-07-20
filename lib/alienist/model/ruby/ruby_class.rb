module Alienist
  module Model
    class RubyClass
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
  end
end
