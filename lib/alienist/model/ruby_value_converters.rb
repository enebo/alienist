module Alienist
  module Model
    module RubyValueConverters
      module NoReferences
        def references(_)
          []
        end
      end

      class ArrayConverter
        def references(obj)
          values = obj.field('values').field_values
          beg = obj.field('begin').value
          len = obj.field('realLength').value

          values[beg...(len-beg)].map(&:id)
        end
        alias :data :references
      end

      class FixnumConverter
        include NoReferences

        def data(obj)
          obj.field('value').value
        end
      end

      class FloatConverter
        include NoReferences

        def data(obj)
          obj.field('value').value.to_s
        end
      end

      class StringConverter
        include NoReferences

        def data(obj)
          blobj = obj.field 'value'
          bytes = blobj.field('bytes').field_values
          beg = blobj.field('begin').value
          len = blobj.field('realSize').value

          bytes[beg...(len-beg)]
        end
      end

      class SymbolConverter
        include NoReferences

        def data(obj)
          ":" + obj.field_path('symbol', 'value').field_values
        end
      end

      class DefaultConverter
        include NoReferences

        def data(obj)
          nil
        end
      end

      DEFAULT_CONVERTER = DefaultConverter.new

      CONVERTERS = {
          'Array' => ArrayConverter.new,
          'Fixnum' => FixnumConverter.new,
          'Float' => FloatConverter.new,
          'String' => StringConverter.new,
          'Symbol' => SymbolConverter.new
      }
      def converter_for(ruby_type)
        CONVERTERS[ruby_type] || DEFAULT_CONVERTER
      end
      module_function :converter_for
    end
  end
end