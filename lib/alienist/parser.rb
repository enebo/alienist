require 'alienist/model/java/java_primitives'

module Alienist
  class Parser
    include Alienist::Model::Java

    # Constants used in Java Heap Dumps.  The names map jhat constants.
    VERSION = "JAVA PROFILE 1.0.2\0"
    UNKNOWN, NATIVE_STATIC = 1, 4
    UTF8, HEAP_DUMP, LOAD_CLASS, HEAP_DUMP_END = 0x01, 0x0c, 0x02, 0x2c
    HEAP_DUMP_SEGMENT, FRAME, TRACE = 0x1c, 0x04, 0x05
    CLASS_DUMP, INSTANCE_DUMP = 0x20, 0x21
    OBJ_ARRAY_DUMP, PRIM_ARRAY_DUMP = 0x22, 0x23
    GC_ROOT_UNKNOWN, GC_ROOT_THREAD_OBJ, GC_ROOT_JNI_GLOBAL = 0xff, 0x08, 0x01
    GC_ROOT_JNI_LOCAL, GC_ROOT_JAVA_FRAME = 0x02, 0x03
    GC_ROOT_NATIVE_STACK, GC_ROOT_STICKY_CLASS = 0x04, 0x05
    GC_ROOT_THREAD_BLOCK, GC_ROOT_MONITOR_USED = 0x06, 0x07

    def initialize(io, snapshot, debug=0)
      @io, @snapshot, @debug = io, snapshot, debug
      @stack_frames = {} # FIXME: Move to snapshot
      @stack_traces = {} # FIXME: Move to snapshot
      @thread_objects = {} # FIXME: Move to snapshot
    end

    def parse
      version = read_version_header
      @io.identifier_size = @io.read_int
      @snapshot.minimum_object_size = 2 * @io.identifier_size # Don't know the 2 ids?
      creation_date = @io.read_date
      @snapshot.parsing(self) do
        loop do
          type = @io.read_type
          break unless type # EOF
          timestamp = @io.read_timestamp
          length = @io.read_int

          case(type)
          when UTF8 then
            id = @io.read_id
            chars = @io.read_bytes(length - @io.identifier_size).force_encoding("UTF-8")
            @snapshot.register_name id, chars
          when HEAP_DUMP then
            puts "Loading HEAP #{length}" if @debug > 0
            read_heap_dump length
          when LOAD_CLASS then
            puts "Loading CLASS #{length}" if @debug > 0
            load_class
          when HEAP_DUMP_END then
            puts "Loading HEAP END #{length}" if @debug > 0
            @io.skip_bytes length, "heap_dump_end"
          when HEAP_DUMP_SEGMENT then
            puts "Loading HEAP SEGMENT #{length}" if @debug > 0
            read_heap_dump length
          when FRAME then
            puts "Loading FRAME #{length}" if @debug > 0
            read_frame length
          when TRACE then
            puts "Loading TRACE #{length}" if @debug > 0
            read_trace length
          else
            @io.skip_bytes length, "parse_else"
          end
        end
      end
    end

    def read_frame(length)
      id, method_name = @io.read_id, @snapshot.name(@io.read_id)
      signature, file = @snapshot.name(@io.read_id), @snapshot.name(@io.read_id)
      serial, line = @io.read_int, @io.read_int
      class_name = @snapshot.serial2cname serial

      @stack_frames[id] = [method_name, signature, class_name, file, line]
    end

    def read_trace(length)
      serial, thread_seq, length = @io.read_int, @io.read_int, @io.read_int
      frames = []
      length.times do |i|
        frame_id = @io.read_id
        frames << @stack_frames[frame_id]
      end
      @stack_traces[serial] = frames
    end

    def read_heap_dump(amount)
      while amount > 0
        pos = @io.pos
        type = @io.read_type
        case(type)
        when GC_ROOT_UNKNOWN then
          puts "Subloading GC_ROOT_UNKNOWN" if @debug > 0
          @snapshot.add_root @io.read_id, 0, UNKNOWN, ""
        when GC_ROOT_THREAD_OBJ then
          puts "Subloading GC_ROOT_THREAD_OBJ" if @debug > 0
          id, thread_seq, stack_seq = @io.read_id, @io.read_int, @io.read_int
          @thread_objects[thread_seq] = [id, stack_seq]
        when GC_ROOT_JNI_GLOBAL then
          puts "Subloading GC_ROOT_JNI_GLOBAL" if @debug > 0
          id, _ = @io.read_id, @io.read_id # ignored global_ref_id
          @snapshot.add_root @io.read_id, 0, NATIVE_STATIC, ""
        when GC_ROOT_JNI_LOCAL then
          puts "Subloading GC_ROOT_JNI_LOCAL" if @debug > 0
          id, thread_seq, depth = @io.read_id, @io.read_int, @io.read_int
          @thread_objects[thread_seq]
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_JAVA_FRAME then
          puts "Subloading GC_ROOT_JAVA_FRAME" if @debug > 0
          id, thread_seq, depth = @io.read_id, @io.read_int, @io.read_int
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_NATIVE_STACK then
          puts "Subloading GC_ROOT_NATIVE_STACK" if @debug > 0
          id, thread_seq= @io.read_id, @io.read_int
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_STICKY_CLASS then
          puts "Subloading GC_ROOT_STICKY_CLASS" if @debug > 0
          id = @io.read_id
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_THREAD_BLOCK then
          puts "Subloading GC_ROOT_THREAD_BLOCK" if @debug > 0
          id, thread_seq = @io.read_id, @io.read_int
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_MONITOR_USED then
          puts "Subloading GC_ROOT_MONITOR_USED" if @debug > 0
          id = @io.read_id
        when CLASS_DUMP then
          puts "Subloading CLASS_DUMP" if @debug > 0
          read_class_dump
        when INSTANCE_DUMP then
          puts "Subloading INSTANCE_DUMP" if @debug > 0
          read_instance_dump
        when OBJ_ARRAY_DUMP then
          puts "Subloading OBJ_ARRAY_DUMP" if @debug > 0
          read_array_dump
        when PRIM_ARRAY_DUMP then
          puts "Subloading PRIM_ARRAY_DUMP" if @debug > 0
          read_primitive_array_dump
        else
          puts "Subloading NOTHING? #{type}" if @debug > 0
        end
        amount -= @io.pos - pos
      end
    end

    def load_class
      serial, class_id, stack_serial = @io.read_int, @io.read_id, @io.read_int
      class_name_id = @io.read_id

      name = @snapshot.name(class_name_id).gsub('/', '.')
      @snapshot.register_cname name, class_id, serial
      puts "ID: #{class_name_id}, NAME: #{name}" if @debug > 3
    end

    def read_array_dump
      read_section do |id, serial|
        length, class_id = @io.read_int, @io.read_id
        @snapshot.add_object_array id, serial, length, class_id, @io.pos
        
        @io.skip_bytes length * @io.identifier_size, "array_dump"
      end
    end

    def read_primitive_array_dump
      read_section do |id, serial|
        length, type_id = @io.read_int, @io.read_type
        signature, element_size = signature_for type_id
        @snapshot.add_value_array id, serial, length, signature, @io.pos
        
        @io.skip_bytes length * element_size, "primitive_array_dump"
      end
    end

    def read_instance_dump
      read_section do |id, serial|
        class_id, length = @io.read_id, @io.read_int

        value_offset = @io.pos
        # We skip field values until whole system loaded so that
        # all classes can be resolved.  we save position for that
        # later parsing into the memory image for that object.
        @io.skip_bytes length, "instance_dump"

        puts "+I 0x#{id.to_s(16)} 0x#{class_id.to_s(16)}" if @debug > 10
        @snapshot.add_instance id, serial, class_id, value_offset, length
      end
    end

    ##
    # This is called by java_object after java_class data has been
    # resolved.  This is not directly called during first phase of parse.
    def read_instance_fields(cls, io_offset)
      @io.seek io_offset  # Move to the instance field data
      values = []
      cls.instance_fields do |field|
        value = TYPE_READS[field.signature].create(@io)

        if value.kind_of? JavaObjectRef # FIXME: don't want this if
          field.value_id = value.value
          puts "+F 0x#{value.value.to_s(16)}" if @debug > 10
          value = @snapshot.resolve_object_ref value.value
        end
        
        values << value
      end
      values
    end

    ##
    # This is called by java_value_object after java_class data has been
    # resolved.  This is not directly called during first phase of parse.
    def read_array_fields(cls, io_offset, length, signature)
      @io.seek io_offset  # Move to the field data

      element_size = TYPE_SIZES_MAP[signature]

      bytes = @io.read_bytes(element_size * length)
    end

    def read_class_dump
      read_section do |id, serial|
        name = @snapshot.id2cname(id) || "unknown_name@#{id}" 
        super_id, classloader_id, signers_id, 
            protection_domain_id, _, _  = @io.read_ids 6
        instance_size = @io.read_int

        skip_constant_pool_entries(@io.read_unsigned_short)

        class_ref = @snapshot.add_class id, name, super_id, classloader_id,
                                        signers_id, protection_domain_id,
                                        instance_size

        puts "+C 0x#{id.to_s(16)} #{name}" if @debug > 10

        read_static_fields(class_ref, @io.read_unsigned_short)
        read_fields(class_ref, @io.read_unsigned_short)
      end
    end

    def read_value_for(type)
      TYPE_READS[type].parse @io
    end

    def read_static_fields(class_ref, count)
      count.times do   # process all static fields
        name_id, type_id = @io.read_id, @io.read_type
        type, _ = signature_for type_id
        value = read_value_for(type)
        @snapshot.add_static_field class_ref, name_id, type, value
      end
    end

    def read_fields(class_ref, count)
      count.times do       # process all static fields
        name_id, type_id = @io.read_id, @io.read_byte
        type, _ = signature_for type_id
        @snapshot.add_field class_ref, name_id, type
      end
    end

    def read_version_header
      # We don't care about pre-Java 6 here so we only want to match 1.0.2 and
      # send a sensible error otherwise.

      # FIXME Verify it matches version
      @io.read_bytes(VERSION.length)
    end

    def read_section
      id, serial = @io.read_id, @io.read_int
      yield id, @stack_traces[serial]
    end

    def skip_constant_pool_entries(count)
      count.times do                   # skip constant pool entries
        @io.read_unsigned_short        # skip index
        type = @io.read_type           # get type of value to skip
        read_value_for type            # skip value
      end
    end

    def signature_for(id)
      return TYPES[id], TYPE_SIZES[id]
    end

    TYPES      = [nil, nil, 'L', nil, 'Z', 'C', 'F', 'D', 'B', 'S', 'I', 'J']
    TYPE_SIZES = [nil, nil, nil, nil,  1,   2,   4,   8,   1,   2,   4,   8]
    TYPE_SIZES_MAP = { # L might be 4...maybe
      'L' => 8, 'Z' => 1, 'C' => 2, 'F' => 4, 'D' => 8,
      'B' => 1, 'S' => 2, 'I' => 4, 'J' => 8
    }
    TYPE_READS = {
      'L' => Alienist::Model::Java::JavaObjectRef, 
      'Z' => Alienist::Model::Java::JavaBoolean, 
      'C' => Alienist::Model::Java::JavaChar,
      'F' => Alienist::Model::Java::JavaFloat,
      'D' => Alienist::Model::Java::JavaDouble,
      'B' => Alienist::Model::Java::JavaByte,
      'S' => Alienist::Model::Java::JavaShort,
      'I' => Alienist::Model::Java::JavaInt,
      'J' => Alienist::Model::Java::JavaLong
    }

  end
end
