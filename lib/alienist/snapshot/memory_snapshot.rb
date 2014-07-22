require 'alienist/model/java/java_class'
require 'alienist/model/java/java_primitives'
require 'alienist/model/java/java_object'
require 'alienist/model/java/java_field'
require 'alienist/model/java/java_static'
require 'alienist/snapshot/base_snapshot'

module Alienist
  module Snapshot
    class MemorySnapshot < Alienist::Snapshot::BaseSnapshot
      include Alienist::Model::Java
      
      attr_reader :java_lang_class, :instances
      
      def initialize
        super()

        @class_from_name = {}  # name -> java_class
        @class_from_id = {}    # id   -> java_class
        @instances = {}        # id   -> java_object
      end

      def add_class(id, name, super_id, classloader_id, signers_id,
                    protection_domain_id, instance_size)
        cls = Alienist::Model::Java::JavaClass.new self, id, name,
             super_id, classloader_id, signers_id, protection_domain_id,
             instance_size
        @class_from_name[name] = cls
        @class_from_id[id] = cls

        cls
      end

      def add_field(cls, name_id, signature)
        name = name name_id
        cls.fields[name] = JavaField.new name_id, name, signature
      end

      def add_instance(id, serial, class_id, field_io_offset)
        object = JavaObject.new id, serial, class_id, field_io_offset
        @instances[id] = object
        
        object
      end

      def add_static_field(cls, name_id, signature, value)
        name = name name_id
        field = JavaField.new name_id, name, signature
        cls.static_fields[name] = JavaStatic.new field, value
      end

      def name2class(name)
        @class_from_name[name]
      end

      def id2class(id)
        @class_from_id[id]
      end

      def classes
        @class_from_id.values
      end

      def resolve(parser)
        # King of kings of all Java classes.  Special attr for easy access.
        @java_lang_class = name2class 'java.lang.Class'
        @class_from_name.each { |name, cls| cls.resolve }
        @instances.values.each { |instance| instance.resolve(parser, self) }
      end

      def resolve_object_ref(id)
        return JavaNull if id == 0

        @instances[id] # FIXME: Do I need to deal with unresolved objs?
      end

    end
  end
end
