require 'alienist/model/java_boolean'
require 'alienist/model/java_byte'
require 'alienist/model/java_char'
require 'alienist/model/java_double'
require 'alienist/model/java_field'
require 'alienist/model/java_float'
require 'alienist/model/java_int'
require 'alienist/model/java_long'
require 'alienist/model/java_object_ref'
require 'alienist/model/java_short'
require 'alienist/model/java_static'

module Alienist
  class Parser
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
      @names = Hash.new { |hash, k| "unresolved class #{k}"  }
      @names[0] = "" # For 0 id
      @class_name_from_id = {}
      @class_name_from_serial = {}
      @stack_frames = {}
      @stack_traces = {}
      @thread_objects = {}
    end

    def parse
      version = read_version_header
      @io.identifier_size = @io.read_int
      creation_date = @io.read_date
      @snapshot.db.transaction do
      loop do
        type = @io.read_type
        return unless type # EOF
        timestamp = @io.read_timestamp
        length = @io.read_int

        case(type)
        when UTF8 then
          id = @io.read_id
          chars = @io.read_bytes(length - @io.identifier_size).force_encoding("UTF-8")
          @names[id] = chars
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
      id, method_name, signature = @io.read_id, @names[@io.read_id], @names[@io.read_id]
      file, serial, line = @names[@io.read_id], @io.read_int, @io.read_int
      class_name = @class_name_from_serial[serial]

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
#          puts "Subloading GC_ROOT_UNKNOWN" if @debug > 0
          @snapshot.add_root @io.read_id, 0, UNKNOWN, ""
        when GC_ROOT_THREAD_OBJ then
#          puts "Subloading GC_ROOT_THREAD_OBJ" if @debug > 0
          id, thread_seq, stack_seq = @io.read_id, @io.read_int, @io.read_int
          @thread_objects[thread_seq] = [id, stack_seq]
        when GC_ROOT_JNI_GLOBAL then
#          puts "Subloading GC_ROOT_JNI_GLOBAL" if @debug > 0
          id, _ = @io.read_id, @io.read_id # ignored global_ref_id
          @snapshot.add_root @io.read_id, 0, NATIVE_STATIC, ""
        when GC_ROOT_JNI_LOCAL then
#          puts "Subloading GC_ROOT_JNI_LOCAL" if @debug > 0
          id, thread_seq, depth = @io.read_id, @io.read_int, @io.read_int
          @thread_objects[thread_seq]
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_JAVA_FRAME then
#          puts "Subloading GC_ROOT_JAVA_FRAME" if @debug > 0
          id, thread_seq, depth = @io.read_id, @io.read_int, @io.read_int
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_NATIVE_STACK then
#          puts "Subloading GC_ROOT_NATIVE_STACK" if @debug > 0
          id, thread_seq= @io.read_id, @io.read_int
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_STICKY_CLASS then
#          puts "Subloading GC_ROOT_STICKY_CLASS" if @debug > 0
          id = @io.read_id
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_THREAD_BLOCK then
#          puts "Subloading GC_ROOT_THREAD_BLOCK" if @debug > 0
          id, thread_seq = @io.read_id, @io.read_int
          # FIXME: Missing logic to store and retrieve
        when GC_ROOT_MONITOR_USED then
#          puts "Subloading GC_ROOT_MONITOR_USED" if @debug > 0
          id = @io.read_id
        when CLASS_DUMP then
#          puts "Subloading CLASS_DUMP" if @debug > 0
          read_class_dump
        when INSTANCE_DUMP then
#          puts "Subloading INSTANCE_DUMP" if @debug > 0
          read_instance_dump
        when OBJ_ARRAY_DUMP then
#          puts "Subloading OBJ_ARRAY_DUMP" if @debug > 0
          read_array_dump
        when PRIM_ARRAY_DUMP then
#          puts "Subloading PRIM_ARRAY_DUMP" if @debug > 0
          read_primitive_array_dump
        else
          puts "Subloading NOTHING?" if @debug > 0
        end
        amount -= @io.pos - pos
      end
    end

    def load_class
      serial, class_id, stack_serial = @io.read_int, @io.read_id, @io.read_int
      class_name_id = @io.read_id

      name = @names[class_name_id].gsub('/', '.')
      @class_name_from_id[class_id] = name
      puts "ID: #{class_name_id}, NAME: #{name}" if @debug > 3
      @class_name_from_serial[class_id] = name
    end

    def read_array_dump
      read_section do |id, serial|
        length, class_id = @io.read_int, @io.read_id
        @io.skip_bytes length * @io.identifier_size, "array_dump"
      end
    end

    def read_primitive_array_dump
      read_section do |id, serial|
        length, type_id = @io.read_int, @io.read_byte
        signature, element_size = signature_for type_id
        @io.skip_bytes length * element_size, "primitive_array_dump"
      end
    end

    def read_instance_dump
      read_section do |id, serial|
        class_id, bytes_following = @io.read_id, @io.read_int
        @io.skip_bytes bytes_following, "instance_dump" 
        # FIXME: Process Unclear if perhaps I should process greedily
        # OR save offset and keep io open OR save blob in DB as part of this
        @snapshot.add_instance(id, serial, class_id, bytes_following)
      end
    end

    def read_class_dump
      read_section do |id, serial|
        name = @class_name_from_id[id] || "unknown_name@#{id}" 
        super_id, classloader_id, signers_id, 
            protection_domain_id, _, _  = @io.read_ids 6
        instance_size = @io.read_int

        skip_constant_pool_entries(@io.read_unsigned_short)
      
        statics = read_static_fields(@io.read_unsigned_short)
        fields = read_fields(@io.read_unsigned_short)
      
        @snapshot.add_class id, name, super_id, classloader_id, signers_id, 
            protection_domain_id, statics, fields, instance_size
      end
    end

    def read_value_for(type)
      TYPE_READS[type].parse @io
    end

    def read_static_fields(count)
      statics = []
      count.times do   # process all static fields
        name_id, type_id = @io.read_id, @io.read_byte
        type, _ = signature_for type_id
        field_name = @names[name_id]
        value = read_value_for(type)
        statics << JavaStatic.new(JavaField.new(name_id, field_name, type), value)
      end
      statics
    end

    def read_fields(count)
      fields = []
      count.times do       # process all static fields
        name_id, type_id = @io.read_id, @io.read_byte
        type, _ = signature_for type_id
        fields << JavaField.new(name_id, @names[name_id], type)
      end
      fields
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
      count.times do            # skip constant pool entries
        @io.read_unsigned_short # index - skip
        @io.read_value_for 0    # value - skip
      end
    end

    def signature_for(id)
      return TYPES[id], TYPE_SIZES[id]
    end

    def inspect
      str = "NAMES = \n"
      @names.each do |id, chars|
        str += "  #{id} = #{chars}\n"
      end
      str
    end

    TYPES      = [nil, nil, 'L', nil, 'Z', 'C', 'F', 'D', 'B', 'S', 'I', 'J']
    TYPE_SIZES = [nil, nil, nil, nil,  1,   2,   4,   8,   1,   2,   4,   8]
    TYPE_READS = {
      'L' => Alienist::JavaObjectRef, 
      'Z' => Alienist::JavaBoolean, 
      'C' => Alienist::JavaChar,
      'F' => Alienist::JavaFloat,
      'D' => Alienist::JavaDouble,
      'B' => Alienist::JavaByte,
      'S' => Alienist::JavaShort,
      'I' => Alienist::JavaInt,
      'J' => Alienist::JavaLong
    }

  end

end
