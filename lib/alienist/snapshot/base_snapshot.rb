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
      def parsing
        puts "AAAAAAA.1"
        yield
        resolve
      rescue
        puts $!
      ensure
        resolve
      end

      ##
      # After parsing has finished we can perform post-processing of
      # data by overriding this methodx
      def resolve
        puts "AAAAA"
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

      def add_instance(id, serial, class_id, bytes_following)
      end

      def add_root(*r)
      end

      def add_static_field(class_ref, name_id, type, value)
      end
    end
  end
end
