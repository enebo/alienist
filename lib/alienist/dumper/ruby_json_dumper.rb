require 'json'

module Alienist
  module Dumper
    class RubyJSONDumper
      def self.dump(snapshot, io=$stdout)
        classes = []
        snapshot.ruby_classes.each do |name, cls|
          instances = cls.ruby_instances.inject([]) do |list, obj|
            instance_hash = {id: obj.id, size: obj.size}

            data = obj.ruby_data_value
            instance_hash[:data] = data if data

            variables = obj.ruby_instance_variables
            instance_hash[:variables] = variables unless variables.empty?

            references = obj.ruby_references
            instance_hash[:references] = references unless references.empty?

            list << instance_hash
          end

          class_hash = {name: name, size: cls.size, id: cls.id}

          class_hash[:instances] = instances unless instances.empty?

          classes << class_hash
        end
        
        io.puts JSON.pretty_generate classes
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
          obj.field_path('symbol', 'value').field_values
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
