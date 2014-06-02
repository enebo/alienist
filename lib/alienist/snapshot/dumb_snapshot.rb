module Alienist
  class DumbSnapshot
    class DumbDB
      def transaction
        yield
      end
    end

    attr_reader :db

    def initialize(db_string="none")
      @db = DumbDB.new
    end

    def add_instance(id, serial, class_id, bytes_following)
    end

    def add_root(*r)
    end

    def add_class(id, name, super_id, classloader_id, signers_id,
                  protection_domain_id, static_fields, fields, instance_size)
    end
  end
end
