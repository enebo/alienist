module Alienist
  module Model
    module Java
      class JavaClass
        attr_reader :instances, :subclasses, :fields, :static_fields, :name
        attr_reader :total_field_count, :field_values, :super_class
        
        def initialize(snapshot, id, name, super_id, classloader_id, signers_id,
                       protection_domain_id, instance_size)
          @snapshot = snapshot
          @classloader_id = classloader_id
          @id, @name, @super_id, @signers_id = id, name, super_id, signers_id
          @protection_domain_id, @instance_size = protection_domain_id, instance_size
          @instances = []
          @subclasses = []
          @fields = {}
          @static_fields = {}
        end

        # We resolve after all classes have been added to the system
        def resolve
          @super_class = @snapshot.id2class @super_id
          # all classes but java.lang.Object
          @super_class.add_subclass self if @super_class 
          @snapshot.java_lang_class.add_instance self
        end

        def add_subclass(cls)
          @subclasses << cls
        end

        def add_instance(object)
          @instances << object
        end

        ##
        # Yield to all fields in this class and all superclasses to yield
        # in reverse-natural-order (how heap stores field info)
        def instance_fields(&block)
          @fields.values.each { |field| block[field] }
          @super_class.instance_fields(&block) if @super_class
        end

        def heap_order_field_names
          names = @fields.keys
          names_rest = @super_class ? @super_class.heap_order_field_names : nil
          names.concat names_rest if names_rest # feeling dumb
          names
        end


        def inspect
          <<-EOS
Name: #{@name}
  Fields : #{@fields.values.join(", ")}
  SFields: #{@static_fields.values.join(", ")}
  SClass: #{@super_class ? @super_class.name : ""}
  subcls: #{@subclasses.map(&:name).join(", ")}
EOS
        end
        alias :to_s :inspect
          
      end
    end
  end
end
