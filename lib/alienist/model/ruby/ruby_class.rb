module Alienist
  module Model
    class RubyClass
      attr_reader :name, :java_id

      def initialize(name, java_id)
        @name, @java_id = name, java_id
        @instances = []
        @subclasses = []
      end

      def resolve(snapshot)
      end
    end
  end
end
