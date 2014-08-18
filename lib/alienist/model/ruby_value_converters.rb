module Alienist
  module Model
    module RubyValueConverters
      CONVERTERS = {
          'Array' => proc do |obj|
            values = obj.field('values').field_values
            beg = obj.field('begin').value
            len = obj.field('realLength').value

            values[beg...(len-beg)].map(&:id)
          end,
          'Fixnum' => proc { |obj| obj.field('value').value },
          #'Float' => proc { |obj| obj.field('value').value },
          'String' => proc do |obj|
            blobj = obj.field 'value'
            bytes = blobj.field('bytes').field_values
            beg = blobj.field('begin').value
            len = blobj.field('realSize').value
            bytes[beg...(len-beg)]
          end,
          'Symbol' => proc { |obj| ":" + obj.field_path('symbol', 'value').field_values },
          # FIXME: Not sure we should have this at all
          'default' => proc { |obj| ""}
      }
      def converter_for(ruby_type)
        CONVERTERS[ruby_type] || CONVERTERS['default']
      end
      module_function :converter_for
    end
  end
end