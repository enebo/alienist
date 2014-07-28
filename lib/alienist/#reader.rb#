module Alienist
  class Reader
    attr_accessor :identifier_size

    SHORT, INT, LONG = 2, 4, 8

    def initialize(io, debug=0)
      @io = io
      @debug = debug
    end

    def pos
      @io.pos
    end

    def small_id?
      @identifier_size == 4
    end

    def read(amount, label="debug")
      str = @io.read amount
      puts "#{label}: '#{str}' (#{str.length})" if @debug >= 9 && str
      str
    end

    def read_boolean
      read_byte('boolean') == '1'
    end

    def read_byte(label="byte")
      byte = read(1, label)
      return nil unless byte
      byte.unpack('C')[0]
    end

    def read_id2(label="id2")
      val = 0
      bytes = read_bytes @identifier_size
      bytes.each_byte do |b|
        val <<= 8
        val |= b & 0xff
      end
      val
    end

    def read_bytes(amount)
      read amount, "bytes"
    end

    def read_char(label='char')
      read(SHORT, label).unpack('a')[0]
    end

    def read_float(label="float")
      read(INT, label).unpack('f')[0]
    end

    def read_id
      small_id? ? read_int("id") : read_long("id")
    end

    def read_ids(number_of_ids=1)
      ids = []
      number_of_ids.times do
        ids << read_id
      end
      ids
    end

    def read_int(label="int")
      read(INT, label).unpack('i!>')[0]
    end

    def read_short(label="ushort")
      read(SHORT, label).unpack('s>')[0]
    end

    def read_unsigned_short(label="ushort")
      read(SHORT, label).unpack('s!>')[0]
    end

    def read_double(label="double")
      read(LONG, label).unpack('d')[0]
    end

    def read_long(label="long")
      read(LONG, label).unpack('l!>')[0]
    end

    def read_timestamp
      read_int "timestamp"
    end

    def read_date
      read_long "date"
    end

    def read_type
      read_byte "type"
    end

    def seek(absolute_amount)
      @io.seek absolute_amount, IO::SEEK_SET
    end

    def skip_bytes(amount, label="")
      puts "skipping #{amount} for #{label}" if @debug >= 7
      @io.seek amount, IO::SEEK_CUR
    end
  end
end
