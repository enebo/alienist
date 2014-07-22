module Alienist
  module Model
    module Java
      class JavaClass
        attr_reader :instances, :subclasses
        
        def initialize(snapshot, id, name, super_id, classloader_id, signers_id,
                       protection_domain_id, instance_size)
          @snapshot = snapshot
          @classloader_id = classloader_id
          @id, @name, @super_id, @signers_id = id, name, super_id, signers_id
          @protection_domain_id, @instance_size = protection_domain_id, instance_size
          @instances = []
          @subclasses = []
        end

        # We resolve after all classes have been added to the system
        def resolve
          @super_class = @snapshot.id2class @super_id
          @super_class.add_subclass self if @super_class

          @snapshot.java_lang_class.add_instance self
        end

        def add_subclass(cls)
          @subclasses << cls
        end

        def add_instance(object)
          @instances << object
        end

        def inspect
          @name
        end
        alias :to_s :inspect
          
      end
    end
  end
end
