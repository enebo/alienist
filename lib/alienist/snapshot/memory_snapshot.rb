require 'alienist/model/java/java_class'
require 'alienist/snapshot/base_snapshot'

module Alienist
  module Snapshot
    class MemorySnapshot < Alienist::Snapshot::BaseSnapshot
      attr_reader :java_lang_class
      
      def initialize
        super()

        @class_from_name = {}  # name -> model_obj:JavaClass
        @class_from_id = {}    # id   -> model_obj:JavaClass
      end

      def add_class(id, name, super_id, classloader_id, signers_id,
                    protection_domain_id, instance_size)
        cls = Alienist::Model::Java::JavaClass.new self, id, name,
             super_id, classloader_id, signers_id, protection_domain_id,
             instance_size
        @class_from_name[name] = cls
        @class_from_id[id] = cls
      end

      def name2class(name)
        @class_from_name[name]
      end

      def id2class(id)
        @class_from_id[id]
      end

      def resolve
        puts "BBBBB"
        # King of kings of all Java classes.  Special attr for easy access.
        @java_lang_class = name2class 'java.lang.Class'
        @class_from_name.each { |name, cls| cls.resolve }
        @class_from_name.each do |name, cls|
          puts "NAME: #{name}, #{cls.subclasses.join(', ')}"
        end

      end
    end
  end
end
