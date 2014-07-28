module Alienist
  module Snapshot
    ##
    # Common identitiy-based information about the heap dump you are processing.
    # This is using a base-class for this because the parser would be incapable
    # of executing if the snapshot did not have these methods.
    class BaseSnapshot
      def initialize
        @class_name_from_id = {}      # {id        -> class_name}
        @class_name_from_serial = {}  # {serial_no -> class_name}
        @names = Hash.new { |hash, k| "unresolved class #{k}"  }
        @names[0] = "" # For 0 id
      end

      def id2cname(id)
        @class_name_from_id[id]
      end

      def name(id)
        @names[id]
      end

      ##
      # Allow snapshot to make a user-friendly string representation
      # of the object.
      def create_pretty_display(obj)
      end

      ##
      # Let snapshot determine whether a user-friendly string can replace
      # the object when being displayed.
      def pretty_display?(obj)
        false
      end

      def process_instance_of?(cls)
        true
      end

      def register_name(id, name)
        @names[id] = name
      end

      def register_cname(cname, id, serial)
        @class_name_from_id[id] = cname
        @class_name_from_serial[serial] = cname
      end

      def serial2cname(serial)
        @class_name_from_serial[serial]
      end

      ##
      # If a snapshot wants to wrap processing in a transaction or do
      # any other resource management then they can override this.
      def parsing(parser)
        yield
        resolve parser
        self
      end

      ##
      # After parsing has finished we can perform post-processing of
      # data by overriding this methodx
      def resolve(parser)
      end

      ##
      # Object by this point should be able to look up real values
      # instead of pointers to those values.
      def resolve_object_ref(id)
      end

      ##
      # returns something which can be used as an opaque pointer for
      # fields and static fields to be passed into add_field and
      # add_static_field.  Different snapshots may return different
      # values.  For in-memory snapshot it might return a reference
      # to a PORO JavaClass.  For a db snapshot it might return
      # a class_id column in the db.
      def add_class(id, name, super_id, classloader_id, signers_id, 
                    protection_domain_id, instance_size)
      end

      def add_field(class_ref, name_id, type)
      end

      def add_instance(id, serial, class_id, field_io_offset)
      end

      def add_object_array(id, serial, length, class_id, field_io_offset)
      end

      def add_root(*r)
      end

      def add_static_field(class_ref, name_id, type, value)
      end
      
      def add_value_array(id, serial, length, signature, field_io_offset)
      end
    end
  end
end
