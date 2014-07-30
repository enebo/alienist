require 'alienist/model/java/java_class'
require 'alienist/model/java/java_primitives'
require 'alienist/model/java/java_object'
require 'alienist/model/java/java_object_array'
require 'alienist/model/java/java_value_array'
require 'alienist/model/java/java_field'
require 'alienist/model/java/java_static'
require 'alienist/model/ruby/ruby_class'
require 'alienist/snapshot/base_snapshot'

module Alienist
  module Snapshot
    class MemorySnapshot < Alienist::Snapshot::BaseSnapshot
      include Alienist::Model::Java
      
      attr_reader :java_lang_class, :java_lang_string
      attr_reader :instances
      
      def initialize
        super()

        @class_from_name = {}  # name -> java_class
        @class_from_id = {}    # id   -> java_class
        @instances = {}        # id   -> java_object
        @ruby_class_from_name = {} # name   -> ruby_class
        @name_from_ruby_class = {} # ruby_class -> name
      end

      def pretty_display?(obj)
        false
      end

      def create_pretty_display(obj)
      end


      def add_class(id, name, super_id, classloader_id, signers_id,
                    protection_domain_id, instance_size)
        cls = JavaClass.new self, id, name, super_id, classloader_id,
                            signers_id, protection_domain_id, instance_size

        case name
        when 'java.lang.String'
          @java_lang_string = cls
        when 'java.lang.Class'
          @java_lang_class = cls
        end
        
        @class_from_name[name] = cls
        @class_from_id[id] = cls

        cls
      end

      def add_field(cls, name_id, signature)
        name = name name_id
        cls.fields << JavaField.new(name_id, name, signature)
      end

      def add_instance(id, serial, class_id, field_io_offset, length)
        object = JavaObject.new id, serial, class_id, field_io_offset,
                                length + minimum_object_size
        @instances[id] = object
        
        object
      end

      def add_object_array(id, serial, length, class_id, field_io_offset)
        object = JavaObjectArray.new id, serial, length, class_id, field_io_offset
        @instances[id] = object
      end

      def add_value_array(id, serial, length, signature, field_io_offset)
        array = JavaValueArray.new id, serial, length, signature, field_io_offset
        @instances[id] = array
      end

      def add_static_field(cls, name_id, signature, value)
        name = name name_id
        field = JavaField.new name_id, name, signature
        cls.static_fields[name] = JavaStatic.new field, value
      end

      def ruby_name2class(name)
        @ruby_class_from_name[name]
      end

      def class2ruby_name(cls)
        @name_from_ruby_class[cls]
      end
      
      def name2class(name)
        @class_from_name[name]
      end

      def id2class(id)
        @class_from_id[id]
      end

      def ruby_classes
        @ruby_class_from_name
      end

      def classes
        @class_from_id.values
      end

      def resolve(parser)
        # King of kings of all Java classes.  Special attr for easy access.
        @java_lang_class = name2class 'java.lang.Class'
        @class_from_id.each { |name, cls| cls.resolve }
        @instances.values.each { |instance| instance.resolve self }
        @instances.values.each { |instance| instance.resolve_fields parser, self }
        #### Going all apeshit since it is getting out of control
        resolve_ruby
      end

      def resolve_object_ref(id)
        return JavaNull if id == 0

        @instances[id] || @class_from_id[id]
      end

      ##### Probably all in some other abtraction but memory_snapshot is already
      ##### mucked over.

      private
      
      def resolve_ruby
        classes.find { |c| c.name == "org.jruby.RubyClass"}.instances.each do |c|
          ruby_name = extract_ruby_name c
          @ruby_class_from_name[ruby_name] = c
          @name_from_ruby_class[c] = ruby_name
        end

        instances.values.find_all do |i|
          i.respond_to?('field') && i.field('metaClass')
        end.each do |i|
          cls = i.field('metaClass')
          cls = ruby_classes['BasicObject'] if !cls.respond_to? 'fields'
          cls.ruby_instances << i
        end

        #@ruby_class_from_name.each do |n, v|
        #  puts "Name: #{n}, Count: #{v.ruby_instances.length}"
        #end
      end

      # FIXME: We can try for cachedName but I am using sure thing even if slower
      def extract_ruby_name(cls)
        base_name = base_name_of cls

        return "ANON:IMPL_ME" unless base_name

        # Likely incorrect if Foo::Object where this Object is not ::Object
        return base_name if base_name == "Object"
        return base_name if base_name == "BasicObject"

        names = [base_name]

        loop do
          cls = cls.field 'parent'
          base_name = base_name_of cls

          break if !base_name || base_name == 'Object'
          names << base_name
        end

        names.reverse.join '::'
      end


      def base_name_of(cls)
        return nil if !cls || cls.kind_of?(JavaNullClass)
        
        base_name_field = cls.field 'baseName'

        return nil if !base_name_field || !base_name_field.respond_to?(:field)
        value = base_name_field.field 'value'
        value && value.respond_to?(:field_values) ? value.field_values.encode("UTF-8") : nil
      end
    end
  end
end
