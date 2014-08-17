require 'json'

module Alienist
  module Dumper
    class RubyJSONDumper
      # Hmmm I don't want to do this by hand but I need to not dump my
      # entire POROs
      def self.dump(snapshot, io=$stdout)
        classes = []
        snapshot.ruby_classes.each do |name, cls|
          instances = cls.ruby_instances.inject([]) do |list, obj|
            variables = dump_variables(name, cls, obj)
            list << {id: obj.id, size: obj.size,
                     data: dump_type_data(snapshot, name, obj),
                     variables: variables}
          end

          classes << {name: name, size: cls.size, id: cls.id,
                      instances: instances}
        end
        
        io.puts JSON.generate classes
      end

      def self.dump_variables(snapshot, name, obj)
        metaClass = obj.field('metaClass')

        # BasicObject this is wrong
        return [] unless metaClass.respond_to? :fields

        vtm = metaClass.field('variableTableManager')
        vn = vtm.field('variableNames')
        names = vn.field_values.inject([]) do |list, str|
          list << str.field('value').field_values
        end

        vt = obj.field('varTable')

        # Deal with values stored elsewhere
        return [] if vt == Alienist::Model::Java::JavaNull

        names.zip(vt.field_values.map(&:id))
      end

      def self.dump_type_data(snapshot, name, obj)
        case name
        when 'Array'
          values = obj.field('values').field_values
          beg = obj.field('begin').value
          len = obj.field('realLength').value
#          puts "BEG: #{beg}, LEN: #{len} VALUES: #{values}"
          values[beg...(len-beg)].inject do |e|
#            puts "NMMM: #{snapshot.class2ruby_name(e)}"
            dump_type_data snapshot, obj.cls.name, e
          end
        when 'Fixnum'
          obj.field('value').value
#        when 'Float'
#          obj.field('value').value
        when 'String'
          blobj = obj.field 'value'
          bytes = blobj.field('bytes').field_values
          beg = blobj.field('begin').value
          len = blobj.field('realSize').value
          bytes[beg...(len-beg)]
        when 'Symbol'
          str = obj.field('symbol')
          str.field('value').field_values
        else
          ""
        end
      end

      def self.pair(key, value, indent, del=%q{"})
        "#{indent}\"#{key}\": #{del}#{value}#{del}"
      end
    end
  end
end
