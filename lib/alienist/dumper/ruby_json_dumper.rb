module Alienist
  module Dumper
    class RubyJSONDumper
      # Hmmm I don't want to do this by hand but I need to not dump my
      # entire POROs
      def self.dump(snapshot)
        puts "{"
        snapshot.ruby_classes.each do |name, cls|
          dump_pair 'name', name, '  '
          dump_pair 'size', cls.size, '  ', ''
          dump_pair 'id', cls.id, '  ', ''
          puts "  \"instances\": {"
          cls.ruby_instances.each do |obj|
            dump_pair 'id', obj.id, '    ', ''
            dump_pair 'size', obj.size, '    ', ''
            dump_pair 'data', dump_type_data(snapshot, name, obj), '    '
          end
          puts "  },"
        end
        puts "}"
      end

      def self.dump_type_data(snapshot, name, obj)
        case name
        when 'Fixnum'
          obj.field('value').value
        else
          ""
        end
      end

      def self.dump_pair(key, value, indent, del=%q{"})
        puts "#{indent}\"#{key}\": #{del}#{value}#{del},"
      end
    end
  end
end
